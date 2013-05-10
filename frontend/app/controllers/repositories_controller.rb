class RepositoriesController < ApplicationController

  skip_before_filter :unauthorised_access, :only => [:new, :create, :select, :index, :show, :edit, :update, :delete]
  before_filter(:only => [:select, :index, :show]) {|c| user_must_have("view_repository")}
  before_filter(:only => [:new, :create, :edit, :update]) {|c| user_must_have("manage_repository")}
  before_filter(:only => [:delete]) {|c| user_must_have("delete_repository")}

  before_filter :refresh_repo_list, :only => [:show, :new]

  def index
    @search_data = Search.global(search_params.merge({"facet[]" => [], "type[]" => ["repository"]}))
  end

  def new
    @repository = JSONModel(:repository_with_agent).new('repository' => {},
                                                        'agent_representation' => {
                                                          'agent_contacts' => [{}]
                                                        })._always_valid!
  end


  def generate_names(repository_with_agent)
    name = JSONModel(:name_corporate_entity).new
    name['primary_name'] = repository_with_agent['repository']['name'].blank? ? '<generated>' : repository_with_agent['repository']['name']
    name['source'] = 'local'
    name['sort_name'] = name['primary_name']

    repository_with_agent['agent_representation']['names'] = [name]
    if repository_with_agent['agent_representation']['agent_contacts']['0']['name'].blank?
      repository_with_agent['agent_representation']['agent_contacts']['0']['name'] = name['primary_name']
    end
  end


  def create
    generate_names(params[:repository])
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository_with_agent),
                :on_invalid => ->(){
                  if @exceptions[:errors]["repo_code"]
                    @exceptions[:errors]["repository/repo_code"] = @exceptions[:errors].delete("repo_code")
                  end

                  return render :partial => "repositories/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  MemoryLeak::Resources.refresh(:repository)

                  return render :json => @repository.to_hash if inline?
            
                  flash[:success] = I18n.t("repository._frontend.messages.created", JSONModelI18nWrapper.new(:repository => @repository))
                  return redirect_to :controller => :repositories, :action => :new, :last_repo_id => id if params.has_key?(:plus_one)
            
                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def edit
    @repository = JSONModel(:repository_with_agent).find(params[:id])
  end

  def update
    generate_names(params[:repository])
    handle_crud(:instance => :repository,
                :model => JSONModel(:repository_with_agent),
                :replace => false,
                :obj => JSONModel(:repository_with_agent).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  MemoryLeak::Resources.refresh(:repository)

                  flash[:success] = I18n.t("repository._frontend.messages.updated", JSONModelI18nWrapper.new(:repository => @repository))
                  redirect_to :controller => :repositories, :action => :show, :id => id
                })
  end

  def show
    @repository = JSONModel(:repository_with_agent).find(params[:id])
    flash.now[:info] = I18n.t("repository._frontend.messages.selected") if @repository.id === session[:repo_id]
  end

  def select
    selected = @repositories.find {|r| r.id.to_s == params[:id]}
    session[:repo] = selected.uri
    session[:repo_id] = selected.id

    flash[:success] = I18n.t("repository._frontend.messages.changed", JSONModelI18nWrapper.new(:repository => selected))

    redirect_to :root
  end

  def delete
    repository = JSONModel(:repository).find(params[:id])
    repository.delete

    MemoryLeak::Resources.refresh(:repository)

    flash[:success] = I18n.t("repository._frontend.messages.deleted", JSONModelI18nWrapper.new(:repository => repository))
    redirect_to(:controller => :repositories, :action => :index, :deleted_uri => repository.uri)
  end


  private

    def refresh_repo_list
      repo_uri = JSONModel(:repository).uri_for(params[:last_repo_id] || params[:id])
      if @repositories.none?{|repo| repo["uri"] === repo_uri}
        MemoryLeak::Resources.refresh(:repository)
        load_repository_list
      end
    end

end
