require 'rails_helper'
require 'csv'

RSpec.describe SubscriptionCollectionReport do
  describe ".export!" do
    let(:project) { create(:project) }
    let(:user) do
      create(:user,
        name:                  'nome_1',
        email:                 'user_1@email.com',
        phone_number:          '(99)9999-9999',
        cpf:                   'cpf_1',
        address_street:        'rua_1',
        address_number:        'numero_1',
        address_complement:    'complemento_1',
        address_neighbourhood: 'bairro_1',
        address_city:          'cidade_1',
        address_state:         'estado_1',
        address_zip_code:      'cep_1'
      )
    end
    let(:subscription) do
      create(:subscription,
        project:        project,
        user:           user,
        plan:           create(:plan, amount: 5000),
        charges:        '3',
        payment_method: 'bank_billet',
        confirmed_at:   '18/03/2017'
      )
    end
    let(:expected_csv) { File.read("#{Rails.root}/spec/fixtures/reports/apoiadores.csv") }

    subject do
      report_file_path = SubscriptionCollectionReport.new([subscription], project.id).export!
      File.read(report_file_path)
    end

    it "expects the generated csv to match to the expected one" do
      expect(subject).to match(expected_csv)
    end
  end
end
