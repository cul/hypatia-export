

namespace :data do
  namespace :sample do
    desc "Load basic user/collection data"
    task load: :environment do
      group_lito = Group.create!(:name => "LITO")
      
      
      role_admin = Role.create!(:name => "Administrator")
      role_user = Role.create!(:name => "Active User")

      w_sac = Workflow.create!(:name => "Submit - Approve - Commit")
      s_ac = Space.create!(:name => "Academic Commons", :code => "AC", :workflow => w_sac, :workflow_create_role => "Content Owner")

      

      role_space_administrator = Role.create!(:name => "Administrator", :context => s_ac)
      wac_admin = role_space_administrator.children.create!(:name => "Administrator", :context => w_sac)
      
      role_space_approver = Role.create!(:name => "Approver", :context => s_ac)
      wac_approver = role_space_approver.children.create!(:name => "Approver", :context => w_sac)
            
      role_space_contributor = Role.create!(:name => "Contributor", :context => s_ac)
      role_user.children << role_space_contributor
      
      wac_contributor = role_space_contributor.children.create!(:name => "Contributor", :context => w_sac)
      
      wac_content_owner = Role.create!(:name => "Content Owner", :context => w_sac)
      
      w_sac.permissions.create!(:role => wac_admin, :action_list => "View,View All,Create,Administrate,Delete")
      w_sac.permissions.create!(:role => wac_approver, :action_list => "View,View All,Delete")
      w_sac.permissions.create!(:role => wac_content_owner, :action_list => "View,Delete")
      w_sac.permissions.create!(:role => wac_contributor, :action_list => "View,Create")

      ws_not_submitted = w_sac.states.create!(:name => "Not Submitted")
      ws_not_submitted.permissions.create!(:role => wac_admin, :action_list => "View,Edit,Move")
      ws_not_submitted.permissions.create!(:role => wac_approver, :action_list => "View")
      ws_not_submitted.permissions.create!(:role => wac_content_owner, :action_list => "View,Edit,Move")
      
      ws_pending_approval = w_sac.states.create!(:name => "Pending Approval")
      ws_pending_approval.permissions.create!(:role => wac_admin, :action_list => "View,Edit,Move")
      ws_pending_approval.permissions.create!(:role => wac_approver, :action_list => "View,Edit,Move")
      ws_pending_approval.permissions.create!(:role => wac_content_owner, :action_list => "View")

      ws_approved = w_sac.states.create!(:name => "Approved")
      ws_approved.permissions.create!(:role => wac_admin, :action_list => "View,Edit,Move")
      ws_approved.permissions.create!(:role => wac_approver, :action_list => "View,Edit,Move")
      ws_approved.permissions.create!(:role => wac_content_owner, :action_list => "View")

      ws_committed = w_sac.states.create!(:name => "Committed")
      ws_committed.permissions.create!(:role => wac_admin, :action_list => "View")
      ws_committed.permissions.create!(:role => wac_approver, :action_list => "View")
      ws_committed.permissions.create!(:role => wac_content_owner, :action_list => "View")

      wt_submit = ws_not_submitted.transition_starts.create!(:name => "Submit", :end_state => ws_pending_approval)
      wt_submit.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_submit.permissions.create!(:role => wac_content_owner, :action_list => "Activate")
      
      wt_withdraw = ws_pending_approval.transition_starts.create!(:name => "Withdraw", :end_state => ws_not_submitted)
      wt_withdraw.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_withdraw.permissions.create!(:role => wac_content_owner, :action_list => "Activate")


      wt_reject = ws_pending_approval.transition_starts.create!(:name => "Reject", :end_state => ws_not_submitted)
      wt_reject.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_reject.permissions.create!(:role => wac_approver, :action_list => "Activate")
      
      wt_approved = ws_pending_approval.transition_starts.create!(:name => "Approve", :end_state => ws_approved)
      wt_approved.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_approved.permissions.create!(:role => wac_approver, :action_list => "Activate")

      
      wt_unapprove = ws_approved.transition_starts.create!(:name => "Unapprove", :end_state => ws_pending_approval)
      wt_unapprove.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_unapprove.permissions.create!(:role => wac_approver, :action_list => "Activate")
      
      wt_commit = ws_approved.transition_starts.create!(:name => "Commit", :end_state => ws_committed)
      wt_commit.permissions.create!(:role => wac_admin, :action_list => "Activate")
      wt_commit.permissions.create!(:role => wac_approver, :action_list => "Activate")
      

      w_single_state = Workflow.create!(:name => "Single State Workflow")
      ws_unsubmitted = w_single_state.states.create!(:name => "Unsubmitted")
      
      role_single_owner = Role.create!(:name => "Administrator", :context => w_single_state)
      role_single_editor = Role.create!(:name => "Editor", :context => w_single_state)
      
      w_single_state.permissions.create!(:role => role_single_owner, :action_list => "View,View All,Create,Administrate,Delete")
      w_single_state.permissions.create!(:role => role_single_editor, :action_list => "View,View All,Create,Delete")

      ws_unsubmitted.permissions.create!(:role => role_single_owner, :action_list => "View,Edit,Move")      
      ws_unsubmitted.permissions.create!(:role => role_single_editor, :action_list => "View,Edit,Move")
      
      
      pr = Option.create!(:name => "default_personal_space_workflow", :value => w_single_state.id)
      pr2 = Option.create!(:name => "default_personal_space_owner_role", :value => "Administrator")
      pr3 = Option.create!(:name => "default_personal_space_creator_role", :value => "Editor")
      
      
      u1 = User.build_from_uni("jws2135", :build_personal_space => true)
      role_admin.assignments.create!(:subject => u1)
      role_user.assignments.create!(:subject => u1)
      group_lito.memberships.create!(:user => u1)
      
      u2 = User.build_from_uni("sh2771", :build_personal_space => true)
      role_admin.assignments.create!(:subject => u2)
      role_user.assignments.create!(:subject => u2)
      role_space_administrator.assignments.create!(:subject => u2)

      u3 = User.build_from_uni("ba2213", :build_personal_space => true)
      role_user.assignments.create!(:subject => u3)

      u4 = User.build_from_uni("jd2148", :build_personal_space => true)
      role_user.assignments.create!(:subject => u4)
      role_space_approver.assignments.create!(:subject => u4)
      
      v = Vocabulary.create!(:name => "DPTS Departments")
      v.members.create!(:name => "LITO")
      v.members.create!(:name => "LDPD")
      v.members.create!(:name => "CDRS")
      v.members.create!(:name => "CCNMTL")
      v.members.create!(:name => "DPTS Wide", :position => "-1")
      
    end
  end
end
