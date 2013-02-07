describe "routing to resources" do

  it "routes /resources/cut to resources#cut" do
    expect(:get => "/resources/cut/FILENAME-100-200-300-1-0-tri.png").to route_to(
      :controller => "resources",
      :action => "cut",
      :file_name => 'FILENAME',
      :aspect_x => '100',
      :aspect_y => '200',
      :width => '300',
      :snap => '1',
      :gravity => '0',
      :effects => 'tri',
      :format => 'png'
    )
  end

  it "does not expose all CRUD actions" do
    expect(:get => "/resources/1/create").not_to be_routable
    expect(:get => "/resources/show").not_to be_routable
    expect(:get => "/resources/update").not_to be_routable
    expect(:get => "/resources/edit").not_to be_routable
    expect(:get => "/resources/new").not_to be_routable
    expect(:get => "/resources/destroy").not_to be_routable
  end

  it "requires numerical dimensions" do
    expect(:get => "/resources/cut/FILENAME-A10-200-300-0-0-0.png").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-B20-300-0-0-0.png").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-C30-0-0-0.png").not_to be_routable
  end

  it "requires snap and gravity to be 0 or 1" do
    expect(:get => "/resources/cut/FILENAME-100-200-300-2-0-0.png").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-A-0-0.png").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-2-0.png").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-A-0.png").not_to be_routable
  end

  it "requires a graphic format" do
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-0-0.css").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-0-0.html").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-0-0.js").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-0-0.json").not_to be_routable
    expect(:get => "/resources/cut/FILENAME-100-200-300-0-0-0.xml").not_to be_routable
  end
end
