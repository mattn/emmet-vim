function! zencoding#lorem#en#expand(command)
  let wcount = matchstr(a:command, '^\%(lorem\|lipsum\)\(\d*\)}$', '\1', '')
  let wcount = wcount > 0 ? wcount : 30
  
  let common = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipisicing', 'elit']
  let words = ['exercitationem', 'perferendis', 'perspiciatis', 'laborum', 'eveniet',
  \            'sunt', 'iure', 'nam', 'nobis', 'eum', 'cum', 'officiis', 'excepturi',
  \            'odio', 'consectetur', 'quasi', 'aut', 'quisquam', 'vel', 'eligendi',
  \            'itaque', 'non', 'odit', 'tempore', 'quaerat', 'dignissimos',
  \            'facilis', 'neque', 'nihil', 'expedita', 'vitae', 'vero', 'ipsum',
  \            'nisi', 'animi', 'cumque', 'pariatur', 'velit', 'modi', 'natus',
  \            'iusto', 'eaque', 'sequi', 'illo', 'sed', 'ex', 'et', 'voluptatibus',
  \            'tempora', 'veritatis', 'ratione', 'assumenda', 'incidunt', 'nostrum',
  \            'placeat', 'aliquid', 'fuga', 'provident', 'praesentium', 'rem',
  \            'necessitatibus', 'suscipit', 'adipisci', 'quidem', 'possimus',
  \            'voluptas', 'debitis', 'sint', 'accusantium', 'unde', 'sapiente',
  \            'voluptate', 'qui', 'aspernatur', 'laudantium', 'soluta', 'amet',
  \            'quo', 'aliquam', 'saepe', 'culpa', 'libero', 'ipsa', 'dicta',
  \            'reiciendis', 'nesciunt', 'doloribus', 'autem', 'impedit', 'minima',
  \            'maiores', 'repudiandae', 'ipsam', 'obcaecati', 'ullam', 'enim',
  \            'totam', 'delectus', 'ducimus', 'quis', 'voluptates', 'dolores',
  \            'molestiae', 'harum', 'dolorem', 'quia', 'voluptatem', 'molestias',
  \            'magni', 'distinctio', 'omnis', 'illum', 'dolorum', 'voluptatum', 'ea',
  \            'quas', 'quam', 'corporis', 'quae', 'blanditiis', 'atque', 'deserunt',
  \            'laboriosam', 'earum', 'consequuntur', 'hic', 'cupiditate',
  \            'quibusdam', 'accusamus', 'ut', 'rerum', 'error', 'minus', 'eius',
  \            'ab', 'ad', 'nemo', 'fugit', 'officia', 'at', 'in', 'id', 'quos',
  \            'reprehenderit', 'numquam', 'iste', 'fugiat', 'sit', 'inventore',
  \            'beatae', 'repellendus', 'magnam', 'recusandae', 'quod', 'explicabo',
  \            'doloremque', 'aperiam', 'consequatur', 'asperiores', 'commodi',
  \            'optio', 'dolor', 'labore', 'temporibus', 'repellat', 'veniam',
  \            'architecto', 'est', 'esse', 'mollitia', 'nulla', 'a', 'similique',
  \            'eos', 'alias', 'dolore', 'tenetur', 'deleniti', 'porro', 'facere',
  \            'maxime', 'corrupti']
  let ret = []
  let sentence = 0
  for i in range(wcount)
    let arr = common
    if sentence > 0
      let arr += words
    endif
    let r = zencoding#util#rand()
    let word = arr[r % len(arr)]
    if sentence == 0
      let word = substitute(word, '^.', '\U&', '')
    endif
    let sentence += 1
    call add(ret, word)
    if (sentence > 5 && zencoding#util#rand() < 10000) || i == wcount - 1
      if i == wcount - 1
        let endc = "?!..."[zencoding#util#rand() % 5]
        call add(ret, endc)
      else
        let endc = "?!,..."[zencoding#util#rand() % 6]
        call add(ret, endc . ' ')
      endif
      if endc != ','
        let sentence = 0
      endif
    else
      call add(ret, ' ')
    endif
  endfor
  return join(ret, '')
endfunction
