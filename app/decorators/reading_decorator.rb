class ReadingDecorator < Draper::Decorator
  delegate_all

  def todays_chapter(membership)
    reading.chapter.verses.by_version(membership.bible_version).each do |v|
      v.versetext
    end
  end

  # Define presentation-specific methods here. Helpers are accessed through
  # `helpers` (aka `h`). You can override attributes, for example:
  #
  #   def created_at
  #     helpers.content_tag :span, class: 'time' do
  #       object.created_at.strftime("%a %m/%d/%y")
  #     end
  #   end
  #@membership.readings.to_date(Date.today).first.chapter.verses.by_version(@membership.bible_version).each do |v|

end
