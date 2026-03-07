function! emmet#lorem#en#expand(command) abort
  let l:wcount = matchstr(a:command, '\(\d*\)$')
  let l:wcount = l:wcount > 0 ? l:wcount : 30

  let l:common = ['lorem', 'ipsum', 'dolor', 'sit', 'amet', 'consectetur', 'adipisicing', 'elit']
  let l:words = ['exercitationem', 'perferendis', 'perspiciatis', 'laborum', 'eveniet',
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
  let l:ret = []
  let l:sentence = 0
  for l:i in range(l:wcount)
    let l:arr = l:common
    if l:sentence > 0
      let l:arr += l:words
    endif
    let l:r = emmet#util#rand()
    let l:word = l:arr[l:r % len(l:arr)]
    if l:sentence == 0
      let l:word = substitute(l:word, '^.', '\U&', '')
    endif
    let l:sentence += 1
    call add(l:ret, l:word)
    if (l:sentence > 5 && emmet#util#rand() < 10000) || l:i == l:wcount - 1
      if l:i == l:wcount - 1
        let l:endc = '?!...'[emmet#util#rand() % 5]
        call add(l:ret, l:endc)
      else
        let l:endc = '?!,...'[emmet#util#rand() % 6]
        call add(l:ret, l:endc . ' ')
      endif
      if l:endc !=# ','
        let l:sentence = 0
      endif
    else
      call add(l:ret, ' ')
    endif
  endfor
  return join(l:ret, '')
endfunction
