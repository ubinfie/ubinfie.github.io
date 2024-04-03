Jekyll::Hooks.register :posts, :pre_render do |post, _out|
  post.data['author'] = post.data.fetch('contributors', []).join(', ')
end

# We're going to do some find and replace, to replace `@contributorName` with a link to their profile.
Jekyll::Hooks.register :site, :pre_render do |site|
  site.posts.docs.each do |post|
    if post.content
      post.content = post.content.gsub(/@([a-zA-Z0-9_-]+)/) do |match|
        name = match[1..]
        if site.data['CONTRIBUTORS'].key?(name)
          "{% include contributor-badge-inline.html id=\"#{name}\" %}"
        else
          "![#{match}](https://github.com/#{name})"
        end
      end
    end
  end
  site.pages.each do |page|
    if page.content && page.path =~ /\.(md|html)$/
      page.content = page.content.gsub(/@([a-zA-Z0-9_-]+)/) do |match|
        name = match[1..]
        if site.data['CONTRIBUTORS'].key?(name)
          "{% include contributor-badge-inline.html id=\"#{name}\" %}"
        else
          "![#{match}](https://github.com/#{name})"
        end
      end
    end
  end
end

