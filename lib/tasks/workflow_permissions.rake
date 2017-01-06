namespace :data do
  namespace :sample do
    desc "Reform permissions into new workflows"
    task new_workflow_permissions: :environment do
      def build_permission(workflow, name, list)
        Permission.destroy(Permission.by_permissible(workflow).role_name_equals(name))
        Permission.create(:permissible => workflow, :role => Role.by_context(workflow).name_equals(name).first, :action_list => list)
      end
      
      Permission.find(:all, :conditions => { :permissible_type => ["Workflow", "WorkflowState","WorkflowTransition"] }).each { |p| p.destroy }
      w_sac = Workflow.find_by_name("SubmitApproveCommit")
      w_ss = Workflow.find_by_name("SingleStep")
      
      
      build_permission(w_sac, "Administrator","View,View All,Create,Move,Administrate,Delete,Activate_All,Edit_not_submitted,Edit_pending_approval,Edit_rejected,Edit_approved")
      build_permission(w_sac, "Approver","View,View All,Delete,Move,Activate_withdraw,Activate_reject,Activate_approve,Activate_submit,Edit_not_submitted,Edit_pending_approval,Edit_rejected")
      build_permission(w_sac, "Contributor","View,Create")
      build_permission(w_sac, "Content Owner","View,Delete,Move,Edit_not_submitted,Edit_rejected,Activate_submit,Activate_withdraw")

      build_permission(w_ss, "Administrator","View,View All,Create,Move,Administrate,Delete,Activate_All,Edit_All")
      build_permission(w_ss, "Editor","View,View All,Create,Delete,Activate_All,Edit_All")
      
    end
  end
end