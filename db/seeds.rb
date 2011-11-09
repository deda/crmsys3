# тарифные планы ---------------------------------------------------------------
puts '=== Seed tariff plans'
account_tariff_plan_min = AccountTariffPlan.create!(
  :name             => 'Минимальный',
  :max_users        => 3,
  :max_mbytes       => 512,
  :max_contacts     => 250,
  :with_commodities => false,
  :with_cases       => false,
  :with_projects    => false)
account_tariff_plan_mid = AccountTariffPlan.create!(
  :name             => 'Базовый',
  :max_users        => 5,
  :max_mbytes       => 1024,
  :max_contacts     => 1000,
  :with_commodities => false,
  :with_cases       => true,
  :with_projects    => false)
account_tariff_plan_max = AccountTariffPlan.create!(
  :name             => 'Максимальный',
  :max_users        => 100,
  :max_mbytes       => 10240,
  :max_contacts     => 10000,
  :with_commodities => true,
  :with_cases       => true,
  :with_projects    => true)

# управляющий аккаунт ----------------------------------------------------------
puts '=== Seed director accounts'
director_account = Account.create!(
  :name         => "Консоль управления",
  :is_director  => true,
  :tariff_plan  => account_tariff_plan_max,
  :end_time     => Date.commercial(3000, 2, 2))

# админ и пользователь управляющего аккаунта -----------------------------------
puts '=== Seed director users'
director_admin = User.for_account(director_account).new
director_admin.name                   = 'Администратор'
director_admin.email                  = 'admin@director.com'
director_admin.password               = '1111'
director_admin.email_confirmed        = true
director_admin.is_admin               = true
director_admin.save!
director_user = User.for_account(director_account).new
director_user.name                   = 'Пользователь'
director_user.email                  = 'user@director.com'
director_user.password               = '1111'
director_user.email_confirmed        = true
director_user.is_admin               = false
director_user.save!



################################################################################
# данные которые будут посеяны во вновь создаваемые аккануты -------------------
################################################################################

director_account = Account.find(:first, :conditions => {:is_director => true})
director_admin = director_account.admins[0]

# настройки управленческого аккаунта -------------------------------------------
director_account.settings.locale = 'ru'
director_account.settings.save

# ТИПЫ -------------------------------------------------------------------------
# типы телефонных номеров ------------------------------------------------------
puts '=== Seed director phone types'
phone_type = PhoneType.for_user(director_admin).create!([
  { :name  => 't(:type_work)',
    :value => 'work,voice'
  },
  { :name  => 't(:type_work_cell)',
    :value => 'work,cell,voice,msg'
  },
  { :name  => 't(:type_work_fax)',
    :value => 'work,fax,voice'
  },
  { :name  => 't(:type_home)',
    :value => 'home,voice'
  },
  { :name  => 't(:type_home_cell)',
    :value => 'home,cell,voice,msg'
  },
  { :name  => 't(:type_home_fax)',
    :value => 'home,fax,voice'
  },
  { :name  => 't(:type_car)',
    :value => 'car,voice'
  },
  { :name  => 't(:type_car_cell)',
    :value => 'car,cell,voice,msg'
  },
  { :name  => 't(:type_pref)',
    :value => 'pref'
  },
  { :name  => 't(:type_other)',
    :value => 'other'
  }])
# типы адресов электронных ящиков ----------------------------------------------
puts '=== Seed director e-mail types'
email_type = EmailType.for_user(director_admin).create!([
  { :name  => 't(:type_work)',
    :value => 'internet,work'
  },
  { :name  => 't(:type_home)',
    :value => 'internet,home'
  },
  { :name  => 't(:type_pref)',
    :value => 'internet,pref'
  },
  { :name  => 't(:type_other)',
    :value => 'other'
  }])
# типы адресов -----------------------------------------------------------------
puts '=== Seed director address types'
address_type = AddressType.for_user(director_admin).create!([
  { :name  => 't(:type_work)',
    :value => 'work'
  },
  { :name  => 't(:type_home)',
    :value => 'home'
  },
  { :name  => 't(:type_juridical)',
    :value => 'other'
  },
  { :name  => 't(:type_real)',
    :value => 'other'
  },
  { :name  => 't(:type_regi)',
    :value => 'other'
  },
  { :name  => 't(:type_postal)',
    :value => 'other'
  },
  { :name  => 't(:type_shipping)',
    :value => 'other'
  },
  { :name  => 't(:type_other)',
    :value => 'other'
  }])
# типы веб-адресов -------------------------------------------------------------
puts '=== Seed director web-address types'
url_type = UrlType.for_user(director_admin).create!([
  { :name  => 't(:type_work)',
    :value => 'work'
  },
  { :name  => 't(:type_home)',
    :value => 'home'
  },
  { :name  => 't(:type_other)',
    :value => 'other'
  }])
# типы месседжера --------------------------------------------------------------
puts '=== Seed director im types'
im_type = ImType.for_user(director_admin).create!([
  { :name  => 't(:type_work)',
    :value => 'work'
  },
  { :name  => 't(:type_home)',
    :value => 'home'
  },
  { :name  => 't(:type_other)',
    :value => 'other'
  }])
# протокол месседжера ----------------------------------------------------------
puts '=== Seed director im protocols'
im_protocol = ImProtocol.for_user(director_admin).create!([
  { :name  => 'ICQ' },
  { :name  => 'AIM' },
  { :name  => 'MSN' },
  { :name  => 'Skype' },
  { :name  => 'Jabber' },
  { :name  => 'Yahoo' }
])

# СТАТУСЫ ----------------------------------------------------------------------
# статусы сделок ---------------------------------------------------------------
puts '=== Seed director sale states'
sale_states = SaleState.for_user(director_admin).create!([
  { :name  => 't(:state_sale_new)',
    :value => '0'
  },
  { :name  => 't(:state_sale_quotation)',
    :value => '10'
  },
  { :name  => 't(:state_sale_specification)',
    :value => '15'
  },
  { :name  => 't(:state_sale_billed)',
    :value => '30'
  },
  { :name  => 't(:state_sale_shipment)',
    :value => '90'
  },
  { :name  => 't(:state_sale_debt)',
    :value => '95'
  },
  { :name  => 't(:state_sale_canceled)',
    :value => '100'
  },
  { :name  => 't(:state_sale_completed)',
    :value => '100'
  }])
# статусы сделок ---------------------------------------------------------------
puts '=== Seed director sale states'
case_states = CaseState.for_user(director_admin).create!([
  { :name  => 't(:state_case_new)' },
  { :name  => 't(:state_case_work)' },
  { :name  => 't(:state_case_canceled)' },
  { :name  => 't(:state_case_completed)' }])
# единицы измерения ------------------------------------------------------------
puts '=== Seed director measures'
measure = Measure.for_user(director_admin).create!([
  { :name => 't(:measure_pc)' },
  { :name => 't(:measure_kg)' }])



################################################################################
# демо-данные ------------------------------------------------------------------
################################################################################
