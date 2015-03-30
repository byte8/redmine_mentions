module RedmineMentions
  module IssuePatch
    def self.included(base)
      base.class_eval do
        after_create :send_mail

        def send_mail
          users = project.users.delete_if { |u| (u.type != 'User' || u.mail.empty? ) }
          users_regex = users.collect { |u| "#{Setting.plugin_redmine_mentions['trigger']}#{u.login}" }.join('|')
          regex_for_email = '\B(' + users_regex + ')'
          regex = Regexp.new(regex_for_email)
          mentioned_users = self.description.scan(regex)

          mentioned_users.each do |mentioned_user|
            username = mentioned_user.first[1..-1]
            if user = User.find_by_login(username)
              MentionMailer.notify_mentioning_issue(self, user).deliver
            end
          end
        end
      end
    end
  end
end
