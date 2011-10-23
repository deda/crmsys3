require 'test_helper'

class ModelExtensionsTest < ActionController::TestCase

  test 'Проверка автоматического удаления неиспользуемых тегов' do
    tag_name_1 = 'метка для контактов 1'
    tag_name_2 = 'метка для контактов 2'

    company = Company.for_user.create(:given_name => 'Тестовая компания')
    tag1 = ContactTag.for_user.create(:name => tag_name_1)
    tag2 = ContactTag.for_user.create(:name => tag_name_2)
    company.tags << tag1
    company.tags << tag2
    company.save!

    tags_count = company.tags.count
    assert tags_count == 2, "Для компании '#{company.name}' сохранено меток: #{tags_count}. Должно быть 2."

    company.tags = [ContactTag.for_account.find_by_name(tag_name_1)]
    company.save!
    assert_nil ContactTag.for_account.find_by_name(tag_name_2), "Не работает автоматическое удаление тега после разрыва связи с владельцем"

    company.destroy
    assert_nil ContactTag.for_account.find_by_name(tag_name_1), "Не работает автоматическое удаление тега после удаления владельца"
  end

end
