<?php
/**
* Userinfo auth plug-in for phpBB3
*
* This plug-in allows authentication using an external userinfo REST endpoint
* as implemented e.g. by Foodsoft. When phpBB runs on the same domain as
* Foodsoft, its login cookie can be used to check if the user is logged in or
* not. If so, the user will be logged into phpBB. When there is no phpBB 
* account yet, it will be created. On each login, the user's phpBB information
* is updated from Foodsoft (this one's pending).
*
* Foodsoft and phpBB users are associated by userid. Since phpBB has a number
* of system users, phpBB users start at an offset as defined by `FOODSOFT_ID_OFFSET`.
*
* Installation (a rough guide):
* - Store this file as includes/auth/auth_foodsoft.php
* - Review the define()s below
* - Make sure Foodsoft's session cookie is shared with phpBB
* - Set FOODSOFT_ADMIN_USERID to the userid you're logged in with in Foodsoft
* - ACP > Client communication > Authentication: set authentication method to Foodsoft
* - Unset FOODSOFT_ADMIN_USERID and reload, to create your real user
* - Reset FOODSOFT_ADMIN_USERID and go to ACP > Users and Groups > Manage users
*     Set a password. Set Founder status and/or put in Administrators group.
* - Unset FOODSOFT_ADMIN_USERID. Now you can use your own account to administer phpBB.
*
* Furthermore, you may want to customize phpBB a bit:
* - Disable signup in ACP
* - Disable user login fields on frontpage (don't know yet how)
* - Disable password form fields in UCP
*   - ACP > Permissions > Group Permissions > Registered Users
*     disable change password and change email
*   - change following lines in includes/ucp/profile.php
*        if (!phpbb_check_hash($data['cur_password'], $user->data['user_password']))
*     into
*        if ($data['new_password'] && !phpbb_check_hash($data['cur_password'], $user->data['user_password']))
*   - in styles/prosilver/template/ucp_profile_reg_details.html (our your style's),
*     surround the <div class="panel"></div> with cur_password input with
*       <!-- IF S_CHANGE_PASSWORD --> and <!-- ENDIF -->
*
*
* @package login
* @version $Id$
* @copyright (c) 2014 wvengen
* @license http://opensource.org/licenses/gpl-license.php GNU Public License
*
* References:
* - http://www.phpbb.com/
* - https://github.com/foodcoops/foodsoft
* - http://code.google.com/p/django-login-for-phpbb/source/browse/trunk/phpbb/auth_django.php
* - https://www.phpbb.com/community/viewtopic.php?f=64&t=993475
*
*/

/**
* @ignore
*/
if (!defined('IN_PHPBB'))
{
  exit;
}

// Session cookie name, this cookie will be passed on to the userinfo endpoint
// You can find this in Foodsoft's config/initializers/session_store.rb as 'key'.
define('FOODSOFT_COOKIE', '_foodsoft_session');
// Foodsoft url (including foodcoop part, or 'f')
define('FOODSOFT_URL', 'https://foodcoop.test/f');
// phpBB's userid are this much higher that Foodsoft's (to give space to phpBB system users)
define('FOODSOFT_ID_OFFSET', 100);
// INSTALL ONLY! which Foodsoft userid maps to phpBB admin (with userid 2)
//define('FOODSOFT_ADMIN_USERID', 1);

// Userinfo REST endpoint
define('FOODSOFT_URL_USERINFO', FOODSOFT_URL.'/login/userinfo');
// Login page to redirect to (will receive return_to parameter)
define('FOODSOFT_URL_LOGIN', FOODSOFT_URL.'/login');
// External logout page to fetch
define('FOODSOFT_URL_LOGOUT', FOODSOFT_URL.'/logout');

/**
 */
function get_foodsoft_user()
{
  $session = $_COOKIE[FOODSOFT_COOKIE];
  if (!isset($session)) return false;

  // http://objectmix.com/php/733452-send-cookie-file_get_contents-request.html
  $ctx = stream_context_create(array('http'=>array('method'=>'GET', 'header'=>"Cookie: ".FOODSOFT_COOKIE."=$session\r\n")));
  $json = file_get_contents(FOODSOFT_URL_USERINFO, FILE_TEXT, $ctx);
  //e.g. $json = '{"user_id": 1, "name": "Klaassen", "given_name": "Jan", "email": "jan@example.com", "locale": "nl"}';
  $data = json_decode($json);

  if (isset($data->error)) return false;
  return $data;
}

/**
 * Sanity check - don't let someone set the auth mode to use Foodsoft unless
 * they themselves are already logged into Foodsoft as a real phpBB user.
 *
 * @return boolean|string false if the user is identified and else an error message
 */
function init_foodsoft()
{
  global $user;

  $foodsoftUser = get_foodsoft_user();
  if (!isset($foodsoftUser) || $user->data['user_id'] != get_userid_foodsoft($foodsoftUser))
  {
    return "You cannot set up Foodsoft authentication unless you are logged into Foodsoft";
  }
  return false;
}

/**
* Login function - allow plain accounts for this (e.g. special admin accounts, and ACP access)
*/
function login_foodsoft($username, $password, $ip = '', $borwser = '', $forwarded_for = '')
{
  require_once 'auth_db.php';
  return login_db($username, $password, $ip, $browser, $forwarded_for);
}

/**
* Autologin function
*
* @return array containing the user row or empty if no auto login should take place
*/
function autologin_foodsoft()
{
  global $db;

  $foodsoftUser = get_foodsoft_user();
  if (!isset($foodsoftUser)) return array();

  $php_auth_user = get_userid_foodsoft($foodsoftUser);
  if ($php_auth_user === false) return array();

  $sql = 'SELECT *
    FROM ' . USERS_TABLE . "
    WHERE user_id = '" . $db->sql_escape($php_auth_user) . "'";
  $result = $db->sql_query($sql);
  $row = $db->sql_fetchrow($result);
  $db->sql_freeresult($result);

  if ($row)
  {
    if ($row['user_type'] == USER_INACTIVE || $row['user_type'] == USER_IGNORE)
      return array();
    update_user_foodsoft($foodsoftUser);
    return $row;
  }

  if (!function_exists('user_add'))
  {
    global $phpbb_root_path, $phpEx;
    include($phpbb_root_path . 'includes/functions_user.' . $phpEx);
  }

  // create the user if he does not exist yet
  $user_id = user_add(user_row_foodsoft($foodsoftUser));
  if ($user_id === false)
  {
    trigger_error('Could not setup phpBB user account. Sorry!', E_USER_ERROR);
  }
  // update id to what we need
  $sql = 'UPDATE ' . USERS_TABLE . '
    SET user_id = ' . $db->sql_escape($php_auth_user) .'
    WHERE user_id = ' . $db->sql_escape($user_id);
  $result = $db->sql_query($sql);
  // TODO check error
  $db->sql_freeresult($result);

  $sql = 'SELECT *
    FROM ' . USERS_TABLE . "
    WHERE user_id = '" . $db->sql_escape($php_auth_user) . "'";
  $result = $db->sql_query($sql);
  $row = $db->sql_fetchrow($result);
  $db->sql_freeresult($result);

  if ($row)
    return $row;
  else
    return array();
}

/**
* This function generates an array which can be passed to the user_add function in order to create a user
*/
function user_row_foodsoft($foodsoftUser)
{
  global $db, $config, $user;
  // first retrieve default group id
  $sql = 'SELECT group_id
    FROM ' . GROUPS_TABLE . "
    WHERE group_name = '" . $db->sql_escape('REGISTERED') . "'
      AND group_type = " . GROUP_SPECIAL;
  $result = $db->sql_query($sql);
  $row = $db->sql_fetchrow($result);
  $db->sql_freeresult($result);

  if (!$row)
  {
    trigger_error('NO_GROUP');
  }

  // TODO find unique username based on real name, handling duplicates
  $username = $foodsoftUser->nickname;
  if (!$username) $username = $foodsoftUser->given_name . ' ' . $foodsoftUser->last_name[0]. '.';

  // generate user account data
  return array(
    'user_id'       => get_userid_foodsoft($foodsoftUser),
    'username'      => $username,
    'user_password' => null, //phpbb_hash($password), TODO check user cannot login with this
    'user_email'    => $foodsoftUser->email,
    'group_id'      => (int) $row['group_id'],
    'user_type'     => USER_NORMAL,
    'user_ip'       => $user->ip,
  );
}

/**
 * Updates user info in database
 */
function update_user_foodsoft(&$foodsoftUser)
{
  global $db, $config, $user;

  $sql = 'UPDATE ' . USERS_TABLE . "
    SET user_email = '" . $db->sql_escape($foodsoftUser->email) . "'
    WHERE user_id = '" . $db->sql_escape(get_userid_foodsoft($foodsoftUser)) . "'";
  $result = $db->sql_query($sql);
  $row = $db->sql_fetchrow($result);
  $db->sql_freeresult($result);

  return true;
}

/**
* Validates whether the user is still logged in
*
* @return boolean true if the given user is authenticated or false if the session should be closed
*/
function validate_session_foodsoft(&$user)
{
  $foodsoftUser = get_foodsoft_user();
  if (!isset($foodsoftUser))
  {
    return false;
  }

  return ($user['user_id'] == get_userid_foodsoft($foodsoftUser)) ? true : false;
}

/**
 * Called when the user session is terminated (for example, the user presses the logout link). 
 *
 * @return none
 */
function logout_foodsoft($user, $new_session)
{
  header('Location: '.FOODSOFT_URL_LOGOUT.'?return_to='.urlencode(get_current_url_foodsoft()), true, 303);
  die();
}

/**
 * Redirect to Foodsoft login page
 */
function redirect_to_foodsoft_login()
{
  header('Location: '.FOODSOFT_URL_LOGIN.'?return_to='.urlencode(get_current_url_foodsoft()), true, 303);
  die();
}

/**
 * Return the current page's URL
 *
 * Works only on Apache, currently.
 *
 */
function get_current_url_foodsoft()
{
  return 'http'.(empty($_SERVER['HTTPS'])?'':'s').'://'.$_SERVER['SERVER_NAME'].$_SERVER['REQUEST_URI'];
}


/**
 * Return userid for Foodsoft user
 *
 * @return integer of phpBB user_id from a remote Foodsoft user
 */
function get_userid_foodsoft($foodsoftUser)
{
  if (empty($foodsoftUser->user_id)) return false;
  $user_id = intval($foodsoftUser->user_id);
  // allow specific user to be admin
  if (defined('FOODSOFT_ADMIN_USERID') && $user_id == constant('FOODSOFT_ADMIN_USERID'))
    return 2; // default admin user_id
  // return user_id for phpBB
  return $user_id + FOODSOFT_ID_OFFSET;
}


/*
 * Big hack - redirect to Foodsoft login when logging into phpBB without being authenticated
 */
if (preg_match('/\\bucp\\.php$/', $_SERVER['PHP_SELF']))
{
  $__user = autologin_foodsoft();
  if (empty($__user))
    redirect_to_foodsoft_login();
}

?>
