# YiffSpace::Auth

Logto-based auth engine for https://yiff.space and related projects. Extracted
from the [yiffspace](https://github.com/YiffSpace/Gem) gem, which this gem
depends on.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "yiffspace-auth"
```

And then execute:

```bash
$ bundle install
```

## Development

This gem depends on [`yiffspace`](https://github.com/YiffSpace/Gem) via git
(see the `Gemfile`). To develop against a local checkout of that repo instead
of the pushed `master` branch, point Bundler at it with a local override:

```bash
$ bundle config set local.yiffspace ../Gem
```

This is stored in `.bundle/config` (gitignored) and doesn't touch the
`Gemfile`/`Gemfile.lock`, so it only affects your machine. Remove it with
`bundle config unset local.yiffspace` to go back to the pushed branch.

## Contributing

Go away

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
