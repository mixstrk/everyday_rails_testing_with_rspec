require "rails_helper"

describe ContactsController do
  let(:admin) { build_stubbed(:admin) }
  let(:user) { build_stubbed(:user) }
  
  let(:contact) { create(:contact, firstname: 'Max', lastname: 'Stark') }

  let(:phones) do
    [
      attributes_for(:phone, phone_type: "home"),
      attributes_for(:phone, phone_type: "office"),
      attributes_for(:phone, phone_type: "mobile")
    ]
  end

  let(:valid_attributes) { attributes_for(:contact) }
  let(:invalid_attributes) { attributes_for(:invalid_contact) }

  shared_examples "public access to contacts" do
    describe "GET #index" do
      context "with params[:letter]" do
        it "populates an array of contacts starting with the letter" do
          smith = create(:contact, lastname: "Smith")
          jones = create(:contact, lastname: "Jones")
          get :index, params: { letter: "S" }
          expect(assigns(:contacts)).to match_array([smith])
        end
        
        it "renders the :index template" do
          get :index, params: { letter: "S" }
          expect(response).to have_http_status(:ok)
            .and render_template :index
        end
      end

      context "without params[:letter]" do
        it "populates an array of all contacts" do
          smith = create(:contact, lastname: "Smith")
          jones = create(:contact, lastname: "Jones")
          get :index
          expect(assigns(:contacts)).to match_array([smith, jones])
        end
        
        it "renders the :index template" do
          get :index
          expect(response).to have_http_status(:ok)
            .and render_template :index
        end
      end
    end

    describe "GET #show" do
      let(:contact) { build_stubbed(:contact,
        firstname: 'Max', lastname: 'Stark') }

        before :each do
          allow(Contact).to receive(:persisted?).and_return(true)
          allow(Contact).to \
            receive(:order).with('lastname, firstname').and_return([contact])
          allow(Contact).to \
            receive(:find).with(contact.id.to_s).and_return(contact)
          allow(Contact).to receive(:save).and_return(true)
  
          get :show, params: { id: contact }
        end
        
      it "assigns the requested contact to @contact" do
        expect(assigns(:contact)).to eq contact
      end

      it "renders the :show template", focus: true do
        expect(response).to have_http_status(:ok)
          .and render_template :show
      end
    end
  end

  shared_examples "full access to contacts" do
    describe "GET #new" do
      it "assigns a new Contact to @contact" do
        get :new
        expect(assigns(:contact)).to be_a_new(Contact)
      end
        
      it "renders the :new template" do
        get :new
        expect(response).to have_http_status(:ok)
          .and render_template :new
      end
    end

    describe "GET #edit" do
      it "assigns the requested contact to @contact" do
        contact = create(:contact)
        get :edit, params: { id: contact }
        expect(assigns(:contact)).to eq contact
      end
        
      it "renders the :show template" do
        contact = create(:contact)
        get :edit, params: { id: contact }
        expect(response).to have_http_status(:ok)
          .and render_template :edit
      end
    end

    describe "POST #create" do
      context "with valid attributes" do
        it "saves the new contact in the database" do
          expect{
            post :create, params: { contact: attributes_for(:contact,
              phones_attributes: phones) }
          }.to change(Contact, :count).by(1)
        end
        
        it "redirects to contacts#show" do
          post :create, params: { contact: attributes_for(:contact,
            phones_attributes: phones) }
          expect(response).to redirect_to contact_path(assigns[:contact])
        end
      end

      context "with invalid attributes" do
        it "does not save the new contact in the database" do
          expect{
            post :create, 
              params: { contact: attributes_for(:invalid_contact) }
          }.to_not change(Contact, :count)
        end
        
        it "re-renders the :new template" do
          post :create, 
            params: { contact: attributes_for(:invalid_contact) }
          expect(response).to render_template :new
        end
      end
    end

    describe "PATCH #update" do

      context "with valid attributes" do
        it "locates the requested @contact" do
          patch :update, params: { id: contact,
            contact: attributes_for(:contact) }
          expect(assigns(:contact)).to eq(contact)
        end

        it "changes @contact's attributes" do
          patch :update, params: { id: contact,
            contact: attributes_for(:contact,
              firstname: "Maxim",
              lastname: "Starkov") }
          contact.reload
          expect(contact.firstname).to eq("Maxim")
          expect(contact.lastname).to eq("Starkov")
        end
        
        it "redirects to the updated contact" do
          patch :update, params: { id: contact,
            contact: attributes_for(:contact) }
          expect(response).to redirect_to contact
        end
      end

      context "with invalid attributes" do
        it "does not change the contact's attributes" do
          patch :update, params: { id: contact,
            contact: attributes_for(:contact,
              firstname: "Maxim",
              lastname: nil) }
          contact.reload
          expect(contact.firstname).to_not eq("Maxim")
          expect(contact.lastname).to eq("Stark")
        end

        it "re-renders the :edit template" do
          patch :update, params: { id: contact,
            contact: attributes_for(:invalid_contact) }
          expect(response).to render_template :edit
        end
      end
    end

    describe "DELETE #destroy" do
      
      it "deletes the contact from the database" do
        contact
        expect{
          delete :destroy, params: { id: contact }
        }.to change(Contact, :count).by(-1)
      end

      it "redirects to users#index" do
        delete :destroy, params: { id: contact }
        expect(response).to redirect_to contacts_url
      end
    end
  end
  
  describe "administrator access" do 
    before :each do
      allow(controller).to receive(:current_user).and_return(admin)
    end

    it_behaves_like "public access to contacts"
    it_behaves_like "full access to contacts"
  end

  describe "user access to contacts" do 
    before :each do
      set_user_session create(:user)
    end

    it_behaves_like "public access to contacts"
    it_behaves_like "full access to contacts"
  end

  describe "guest access to contacts" do
    it_behaves_like "public access to contacts"

    describe "GET #new" do
      it "requires login" do
        get :new
        expect(response).to require_login
      end
    end

    describe "GET #edit" do
      it "requires login" do
        contact = create(:contact)
        get :edit, params: { id: contact }
        expect(response).to require_login
      end
    end

    describe "POST #create" do
      it "requires login" do
        post :create, params: {
          id: create(:contact),
          contact: attributes_for(:contact)
        }
        expect(response).to require_login
      end
    end

    describe "PUT #update" do
      it "requires login" do
        put :update, params: {
          id: create(:contact),
          contact: attributes_for(:contact)
        }
        expect(response).to require_login
      end
    end

    describe "DELETE #destroy" do
      it "requires login" do
        delete :destroy, params: { id: create(:contact) }
        expect(response).to require_login
      end
    end
  end
end
