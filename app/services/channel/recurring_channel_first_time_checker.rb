class Channel::RecurringChannelFirstTimeChecker
  attr_reader :user

  def self.first_time?(user)
    return true if user.nil?

    user.projects.none? { |project| project.recurring? }
  end
end
