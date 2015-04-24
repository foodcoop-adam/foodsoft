# encoding: utf-8
class Admin::WorkgroupsController < Admin::BaseController
  inherit_resources

  def index
    @workgroups = Workgroup.natural_order
    # if somebody uses the search field:
    @workgroups = @workgroups.where('name LIKE ?', "%#{params[:query]}%") unless params[:query].blank?

    @workgroups = @workgroups.page(params[:page]).per(@per_page)
  end

  def destroy
    @workgroup = Workgroup.find(params[:id])
    @workgroup.destroy
    redirect_to admin_workgroups_url, notice: t('admin.workgroups.destroy.notice')
  rescue => error
    redirect_to admin_workgroups_url, alert: t('admin.workgroups.destroy.error')
  end
end
