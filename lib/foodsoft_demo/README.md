FoodsoftDemo
============

Adds demonstration features to foodsoft.

When enabling automatic login, you may want to create a cronjob deleting old
demo users, `rake foodsoft:demo:clean`.

Configuration options in `config/app_config.yml`:
```yaml
  # Replace login with automatic user creation, useful for showcasing member
  # ordering without asking people to login.
  use_demo_autologin: true

  # You may want to disable posting new messages. This can be either true,
  # or admin to allow admins to post.
  restrict_new_message: admin
```

Note that both options are protected by default. If you want foodcoops
to be able to set this in the configuration screen, you need to add
`use_demo_autologin: false` and `restrict_new_message: false` under the
`protected` key in `config/app_config.yml`.
