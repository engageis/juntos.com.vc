class CreateMultiCategoriesChannel
  def initialize(category_ids, channel)
    @channel = channel
    @categories = category_ids
  end

  def call
    @channel.categories = Category.where(id: @categories)
    @channel.save
  end
end
