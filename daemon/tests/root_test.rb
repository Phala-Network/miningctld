scope do
  test 'his life should extend' do 
    get '/'
    assert last_response.ok?
    assert_equal last_response.body, '🐸'
  end
end
