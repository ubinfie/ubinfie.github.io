Jekyll::Hooks.register :posts, :pre_render do |post, _out|
  post.data['author'] = post.data.fetch('contributors', []).join(', ')
end
