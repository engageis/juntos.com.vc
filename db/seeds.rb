# catarse settings table
secret_token = CatarseSettings.find_by(name: 'secret_token')
secret_token.update_attributes(value: ENV['SECRET_TOKEN'])

secret_key_base = CatarseSettings.find_by(name: 'secret_key_base')
secret_key_base.update_attributes(value: ENV['SECRET_KEY_BASE'])

CatarseSettings.create(
  [
    { name: "company_name", value: "Juntos com Você" },
    { name: "company_logo", value: "" },
    { name: "email_contact", value: "contato@juntos.com.vc" },
    { name: "email_no_reply", value: "no-reply@juntos.com.vc" },
    { name: "email_projects", value: "contato@juntos.com.vc" },
    { name: "email_system", value: "contato@juntos.com.vc" },
    { name: "email_payments", value: "financial@administrator.com" },
    { name: "facebook_url", value: "http:g/facebook.com/juntoscomvc" },
    { name: "twitter_url", value: "http://twitter.com/juntoscomvc" },
    { name: "twitter_username", value: "juntoscomvc" },
    { name: "catarse_fee", value: "0.0" },
    { name: "support_forum", value: "http://juntoscomvc.uservoice.com/" },
    { name: "faq_url", value: "http://juntoscomvc.uservoice.com/" },
    { name: "feedback_url", value: "http://juntoscomvc.uservoice.com/" },
    { name: "terms_url", value: "http://suporte.catarse.me/knowledgebase/articles/161100-termos-de-uso" },
    { name: "privacy_url", value: "http://suporte.catarse.me/knowledgebase/articles/161103-pol%C3%ADtica-de-privacidade" },
    { name: "about_channel_url", value: "http://blog.catarse.me/conheca-os-canais-do-catarse/" },
    { name: "instagram_url", value: "https://www.instagram.com/juntos.com.vc/" },
    { name: "github_url", value: "https://github.com/juntos-com-vc" },
    { name: "contato_url", value: "http://juntoscomvc.uservoice.com/" },
    { name: "blog_feed_url", value: "http://juntoscomvc.wordpress.com/feed/" },
    { name: "blog_url", value: "http://juntoscomvc.wordpress.com/" },
    { name: "moip_token", value: ENV['MOIP_TOKEN'] },
    { name: "moip_key", value: ENV['MOIP_KEY'] },
    { name: "moip_uri", value: ENV['MOIP_URI'] },
    { name: "moip_test", value: ENV['MOIP_TEST'] },
    { name: "uservoice_secret_gadget", value: nil },
    { name: "uservoice_key", value: nil },
    { name: "mailchimp_url", value: "" },
    { name: "mailchimp_api_key", value: nil },
    { name: "mailchimp_list_id", value: nil },
    { name: "juntos_gift_card_api_key", value: ENV['JUNTOS_GIFT_CARD_API_KEY'] },
    { name: "juntos_gift_cards_api_key", value: ENV['JUNTOS_GIFT_CARDS_API_KEY'] },
    { name: "google_analytics_id", value: nil },
    { name: "paypal_username", value: nil },
    { name: "paypal_password", value: nil },
    { name: "paypal_signature", value: nil },
    { name: "geo_ip_token", value: nil },
    { name: "sendgrid", value: ENV['SENDGRID_PASSWORD'] },
    { name: "sendgrid_user_name", value: ENV['SENDGRID_USERNAME'] },
    { name: "facebook_app_id", value: nil },
    { name: "garupa_moip_token", value: nil },
    { name: "garupa_moip_key", value: nil },
    { name: "default_color", value: "#ff8a41" },
    { name: "aws_access_key", value: ENV['AWS_ACCESS_KEY'] },
    { name: "aws_secret_key", value: ENV['AWS_SECRET_KEY'] },
    { name: "aws_bucket", value: ENV['AWS_BUCKET'] },
    { name: "project_images_limit", value: "8" },
    { name: "project_partners_limit", value: "3" },
    { name: "host", value: ENV['HOST'] },
    { name: "base_url", value: ENV['BASE_URL'] },
    { name: "base_domain", value: ENV['BASE_DOMAIN'] },
    { name: "secure_host", value: ENV['SECURE_HOST']}
  ]
)

# oauth providers
OauthProvider.find_or_create_by!(name: 'facebook') do |o|
  o.key = ENV['FACEBOOK_KEY']
  o.secret = ENV['FACEBOOK_SECRET']
  o.path = 'facebook'
end

# disable observers
ActiveRecord::Base.observers.disable :all

# admin
User.create(name: 'User Administrator', 
            email: 'user@administrator.com',
            password: 'password',
            admin: true)

# financial admin and staff
User.create(name: 'User Financial Administrator', 
            email: 'financial@administrator.com',
            password: 'password',
            admin: true,
            staffs: [1])

# random users
5.times do |i|
  User.create(name: "User number ##{i}",
              email: "user_#{i}@email.com",
              password: "password#{i}")
end

# categories
3.times do |i|
  Category.create(name_pt: "Categoria ##{i}", name_en: "Category ##{i}", color: "#%06x" % (rand * 0xffffff)) 
end

# select a random record in DB
def random_record(model)
  model.order('RANDOM()').first
end

# channels
3.times do |i|
  Channel.create(name: "Channel ##{i}", description: "Channel ##{i} description", permalink: "channel#{i}", category: random_record(Category))
end

# recurring channel
Channel.create(name: 'Recurring channel', description: 'Recurring channel description', permalink: 'recurring', recurring: true, category_id: 1)

# creating projects
3.times do |i|
  Project.create(name: "Project ##{i}", permalink: "project#{i}", headline: "Headline ##{i}", about: "Project ##{i} about", goal: i*100, online_days: i*10, user: random_record(User), category: random_record(Category))
end

# creating projects in channels
4.upto(6) do |i|
  Project.create(name: "Project ##{i}", permalink: "project#{i}", headline: "Headline ##{i}", about: "Project ##{i} about", goal: i*100, online_days: i*10, user: random_record(User), channels: [ random_record(Channel.recurring(false)) ])
end

# creating projects in recurring channel
7.upto(9) do |i|
  Project.create(name: "Project ##{i}", permalink: "project#{i}", headline: "Headline ##{i}", about: "Project ##{i} about", goal: i*100, user: random_record(User), channels: [ Channel.recurring(true).first ])
end

# making projects online and add contributions
Project.all.each do |project|
  project.send_to_analysis
  project.approve

  3.times do |i|
    contribution = Contribution.create(project: project, user: random_record(User), project_value: rand(100))
    
    if project.recurring?
      recurring_contribution = RecurringContribution.create(project: project, user: contribution.user, value: contribution.project_value)
      contribution.update_attributes(recurring_contribution: recurring_contribution) 
    end

    contribution.confirm
  end
end

# creating one successful project
successful_project = Project.create(name: "Project successful", permalink: "success", headline: "Headline successful", about: "Project successful about", goal: 100, online_days: 10, user: random_record(User), category: random_record(Category))

successful_project.send_to_analysis
successful_project.approve

3.times do |i|
  contribution = Contribution.create(project: successful_project, user: random_record(User), project_value: 50)
  contribution.confirm
end

successful_project.update_attributes(state: 'successful')

# creating one failed project
failed_project = Project.create(name: "Project failed", permalink: "fail", headline: "Headline failed", about: "Project failed about", goal: 100, online_days: 10, user: random_record(User), category: random_record(Category))

failed_project.send_to_analysis
failed_project.approve

3.times do |i|
  contribution = Contribution.create(project: successful_project, user: random_record(User), project_value: 10)
  contribution.confirm
end

failed_project.update_attributes(state: 'failed')

# some random pending contributions
6.times do |i|
  Contribution.create(project: random_record(Project.without_recurring_and_pepsico_channel), user: random_record(User), project_value: rand(50))
end

# who we are texts
Page.create(
  [
    { name: 'who_we_are',
      content: "A Juntos.com.vc já nasceu de pessoas se encontrando, se juntando para mudar a realidade com a qual conviviam. Nossos fundadores são pessoas que sempre foram voluntárias em instituições e sentiam a necessidade de ter algum outro meio para conseguir captar dinheiro para os projetos que queriam ver realizados acontecerem, sem ser pelos às vezes tão árduos patrocínios e editais. 
  De outro lado, pessoas que eram doadoras e perceberam que não sabiam o que acontecia com o dinheiro que doavam para as instituições, queriam um meio de poder acompanhar os projetos acontecendo. 
  
  Essas pessoas se encontraram com essas ideias já na cabeça, e acharam que a melhor forma para colocar isso em prática era por meio do crowdfunding, que nada mais é do que uma vaquinha digital, várias pessoas doando pequenos valores para ver o projeto acontecer!
  
  Da união nasceu a Juntos!",
      content_html: "<p>A Juntos.com.vc já nasceu de pessoas se encontrando, se juntando para mudar a realidade com a qual conviviam. Nossos fundadores são pessoas que sempre foram voluntárias em instituições e sentiam a necessidade de ter algum outro meio para conseguir captar dinheiro para os projetos que queriam ver realizados acontecerem, sem ser pelos às vezes tão árduos patrocínios e editais. <br />
  De outro lado, pessoas que eram doadoras e perceberam que não sabiam o que acontecia com o dinheiro que doavam para as instituições, queriam um meio de poder acompanhar os projetos acontecendo.</p>
  <p>Essas pessoas se encontraram com essas ideias já na cabeça, e acharam que a melhor forma para colocar isso em prática era por meio do crowdfunding, que nada mais é do que uma vaquinha digital, várias pessoas doando pequenos valores para ver o projeto acontecer!</p>
  <p>Da união nasceu a Juntos!</p>",
      locale: :pt },
    { name: 'mission',
      content: "Despertar pessoas em busca de uma transformação social usando a força do coletivo e das redes de comunicação para reduzir diferenças e multiplicar boas ações.",
      content_html: "<p>Despertar pessoas em busca de uma transformação social usando a força do coletivo e das redes de comunicação para reduzir diferenças e multiplicar boas ações.</p>",
      locale: :pt },
    { name: 'vision',
      content: "Ser referência no Terceiro Setor como uma organização sólida e idônea que seleciona projetos de impacto social positivo, estimulando e engajando doadores a participarem dessa mudança.",
      content_html: "<p>Ser referência no Terceiro Setor como uma organização sólida e idônea que seleciona projetos de impacto social positivo, estimulando e engajando doadores a participarem dessa mudança.</p>",
      locale: :pt },
    { name: 'contact',
      content: "Achou bacana mas acha que pode ficar melhor?
  Quer conhecer a gente, trocar ideia, tomar um café?
    Entre em contato, mande sua opinião, crítica, sugestão...
    Queremos melhorar com a ajuda de vocês!

  Envie um e-mail para contato@juntos.com.vc e responderemos o mais breve possível.

    Obrigada,
    Equipe Juntos.com.vc",
    content_html: '<p>Achou bacana mas acha que pode ficar melhor?
  Quer conhecer a gente, trocar ideia, tomar um café?
    Entre em contato, mande sua opinião, crítica, sugestão...
    Queremos melhorar com a ajuda de vocês!</p>

  <p>Envie um e-mail para <a class="alt-link" href="mailto:contato@juntos.com.vc" target="_blank">contato@juntos.com.vc</a> e responderemos o mais breve possível.</p>

  <p>Obrigada,
  Equipe Juntos.com.vc</p>',
    locale: :pt },
  { name: 'values',
    content: "A ética, a transparência, o comprometimento social, o profissionalismo, a inovação, o envolvimento, a idoneidade, a solidez e o espírito de coletividade.",
    content_html: "<p>A ética, a transparência, o comprometimento social, o profissionalismo, a inovação, o envolvimento, a idoneidade, a solidez e o espírito de coletividade.</p>",
    locale: :pt },
  { name: 'goals',
    content: "• Apoiar a captação de recursos para projetos sociais.
    • Contribuir para o aumento da cultura de doação no Brasil.
    • Dar mais visibilidade para projetos sociais.
    • Democratizar a doação no Brasil, ou seja, fazer com que qualquer pessoa possa contribuir com projetos sociais.",
    content_html: "<p>• Apoiar a captação de recursos para projetos sociais.<br />
  • Contribuir para o aumento da cultura de doação no Brasil.<br />
  • Dar mais visibilidade para projetos sociais.<br />
  • Democratizar a doação no Brasil, ou seja, fazer com que qualquer pessoa possa contribuir com projetos sociais.</p>",
    locale: :pt },
  { name: 'mission',
    content: "Despertar pessoas em busca de uma transformação social usando a força do coletivo e das redes de comunicação para reduzir diferenças e multiplicar boas ações.",
    content_html: "<p>Despertar pessoas em busca de uma transformação social usando a força do coletivo e das redes de comunicação para reduzir diferenças e multiplicar boas ações.</p>",
    locale: :en },
  { name: 'vision',
    content: "Ser referência no Terceiro Setor como uma organização sólida e idônea que seleciona projetos de impacto social positivo, estimulando e engajando doadores a participarem dessa mudança.",
    content_html: "<p>Ser referência no Terceiro Setor como uma organização sólida e idônea que seleciona projetos de impacto social positivo, estimulando e engajando doadores a participarem dessa mudança.</p>",
    locale: :en },
  { name: 'values',
    content: "A ética, a transparência, o comprometimento social, o profissionalismo, a inovação, o envolvimento, a idoneidade, a solidez e o espírito de coletividade.",
    content_html: "<p>A ética, a transparência, o comprometimento social, o profissionalismo, a inovação, o envolvimento, a idoneidade, a solidez e o espírito de coletividade.</p>",
    locale: :en },
  { name: 'goals',
    content: "• Apoiar a captação de recursos para projetos sociais.
    • Contribuir para o aumento da cultura de doação no Brasil.
    • Dar mais visibilidade para projetos sociais.
    • Democratizar a doação no Brasil, ou seja, fazer com que qualquer pessoa possa contribuir com projetos sociais.",
    content_html: "<p>• Apoiar a captação de recursos para projetos sociais.<br />
  • Contribuir para o aumento da cultura de doação no Brasil.<br />
  • Dar mais visibilidade para projetos sociais.<br />
  • Democratizar a doação no Brasil, ou seja, fazer com que qualquer pessoa possa contribuir com projetos sociais.</p>",
    locale: :en },
  { name: 'who_we_are',
    content: "Well, the way they make shows is, they make one show. That show's called a pilot. Then they show that show to the people who make shows, and on the strength of that one show they decide if they're going to make more shows. Some pilots get picked and become television programs. Some don't, become nothing. She starred in one of the ones that became nothing.

  Well, the way they make shows is, they make one show. That show's called a pilot. Then they show that show to the people who make shows, and on the strength of that one show they decide if they're going to make more shows. Some pilots get picked and become television programs. Some don't, become nothing. She starred in one of the ones that became nothing.",
    content_html: "<p>Well, the way they make shows is, they make one show. That show&#39;s called a pilot. Then they show that show to the people who make shows, and on the strength of that one show they decide if they&#39;re going to make more shows. Some pilots get picked and become television programs. Some don&#39;t, become nothing. She starred in one of the ones that became nothing.</p>

  <p>Well, the way they make shows is, they make one show. That show&#39;s called a pilot. Then they show that show to the people who make shows, and on the strength of that one show they decide if they&#39;re going to make more shows. Some pilots get picked and become television programs. Some don&#39;t, become nothing. She starred in one of the ones that became nothing.</p>",
    locale: :en },
  { name: 'contact',
    content: "Thought it is nice but can be better?
  Do you want to meet us, exchange information and have a coffee?
  Get in touch, send your opinion, criticize, suggest...
    We want your help to improve ourselves.

    Send an e-mail to contato@juntos.com.vc and we are going to answer as soon as possible.

    Thank You,

    Juntos.com.vc Team",
    content_html: '<p>Thought it is nice but can be better?
  Do you want to meet us, exchange information and have a coffee?
  Get in touch, send your opinion, criticize, suggest...
    We want your help to improve ourselves.</p>

  <p>Send an e-mail to <a class="alt-link" href="mailto:contato@juntos.com.vc" target="_blank">contato@juntos.com.vc</a> and we are going to answer as soon as possible.</p>

  <p>Thank You,</p>

  <p>Juntos.com.vc Team</p>',
  locale: :en }
  ]
)

# enable observers
ActiveRecord::Base.observers.enable :all
