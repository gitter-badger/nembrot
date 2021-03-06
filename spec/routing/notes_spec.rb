# encoding: utf-8

describe 'routing to notes' do
  it 'routes /notes to note#index' do
    expect(get: '/notes').to route_to(
      controller: 'notes',
      action: 'index'
    )
  end

  it 'routes /notes/:id to note#show for id' do
    expect(get: '/notes/1').to route_to(
      controller: 'notes',
      action: 'show',
      id: '1'
    )
  end

  it 'routes /notes/:id/v/:sequence to note#version for id, sequqence' do
    expect(get: '/notes/1/v/1').to route_to(
      controller: 'notes',
      action: 'version',
      id: '1',
      sequence: '1'
    )
  end

  it 'does not expose all CRUD actions' do
    expect(get: '/notes/1/create').not_to be_routable
    pending "expect(get: '/notes/show').to route_to(root_path)"
    pending "expect(get: '/notes/update').to route_to(root_path)"
    pending "expect(get: '/notes/edit').to route_to(root_path)"
    pending "expect(get: '/notes/new').to route_to(root_path)"
    pending "expect(get: '/notes/destroy').to route_to(root_path)"
  end

  it 'requires a numerical id' do
    pending"expect(get: '/notes/abc').to route_to(root_path)"
  end

  it 'requires a numerical sequence' do
    expect(get: '/notes/1/v/abc').not_to be_routable
  end
end
