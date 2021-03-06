class SeamailMessage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia

  field :au, as: :author, type: String
  field :oa, as: :original_author, type: String, default: ->{author}
  field :tx, as: :text, type: String
  field :ts, as: :timestamp, type: Time
  field :rd, as: :read_users, type: Array, default: []
  embedded_in :seamail, inverse_of: :messages

  validates :author, :timestamp, presence: true
  validates :text, presence: true, length: {maximum: 10000}
  validate :validate_author
  validate :validate_original_author

  def validate_author
    return if author.blank?
    unless User.exist? author
      errors[:base] << "#{author} is not a valid username"
    end
  end

  def validate_original_author
    return if original_author.blank?
    unless User.exist? original_author
      errors[:base] << "#{original_author} is not a valid username"
    end
  end

  def author=(username)
    super User.format_username username
  end

  def original_author=(username)
    super User.format_username original_author
  end

end
