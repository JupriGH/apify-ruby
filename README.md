
# Apify Ruby SDK Unofficial

![dont be sad readme is here](https://raw.githubusercontent.com/JupriGH/resources/main/cats/catframe.png)

<img src="https://upload.wikimedia.org/wikipedia/commons/2/28/Apify-logo.svg" width="280">
<img src="https://upload.wikimedia.org/wikipedia/commons/7/73/Ruby_logo.svg" width="80" height="80">


## About  Ruby (programming language)

**Ruby** is an [interpreted](https://en.wikipedia.org/wiki/Interpreted_language "Interpreted language"), [high-level](https://en.wikipedia.org/wiki/High-level_programming_language "High-level programming language"), [general-purpose programming language](https://en.wikipedia.org/wiki/General-purpose_programming_language "General-purpose programming language") which supports multiple [programming paradigms](https://en.wikipedia.org/wiki/Programming_paradigm "Programming paradigm"). It was designed with an emphasis on programming productivity and simplicity. In Ruby, everything is an object, including [primitive data types](https://en.wikipedia.org/wiki/Primitive_data_type "Primitive data type"). It was developed in the mid-1990s by [Yukihiro "Matz" Matsumoto](https://en.wikipedia.org/wiki/Yukihiro_Matsumoto "Yukihiro Matsumoto") in [Japan](https://en.wikipedia.org/wiki/Japan "Japan").

## About This Actor

Apify Ruby SDK Unofficial Unstable Unsupported Under Maintenance.
Inspired by [Apify Python SDK](https://docs.apify.com/sdk/python/)

> **Disclaimer :** This library is community library and not supported by Apify

**Included :**
- Apify SDK (unofficial)
- Apify Client (unofficial)

**Source Code :**

[Github](https://github.com/JupriGH/apify-ruby-sdk)

**Important Notes (for Ruby beginner like me) :**

- On ruby all evaluated to `true` except for: `false` and `nil`.
- Function will return value from last expression.

**Developer Notes**

- Some method is conflicting with Ruby internal method such as: `.initialize`, `.exit`, `.fail`, etc. Renamed to:  `.initialize_`, `.exit_`, `.fail_` etc.

## Basic Usage

```ruby
# SYNC Mode
# won't be able to receive platform events (aborting, migration, etc.)
# for testing on local development (eg: IRB)
Apify::Actor.main(<callable>)

# ASYNC Mode
# use on apify platform to receive platform events
Async do
	Apify::Actor.main(<callable>)
end
```

***Example #1***

```ruby
Apify::Actor.main( lambda { |actor|
	input = actor.get_input
	0 # optional exit code
})
```
or
```ruby
actor = Apify::Actor
actor.main( lambda {
	input = actor.get_input
	0 # optional exit code
})
```

***Example #2***

```ruby
def main(actor)
	input = actor.get_input
end

Apify::Actor.main( method(:main) )
```

### Using "with" *emulator*

Use `with` function to emulate **Python** `context manager`

```ruby
# SYNC Mode
with Apify::Actor do |actor|
	input = actor.get_input
end

# ASYNC Mode
Async do
	with Apify::Actor do |actor|
		input = actor.get_input
	end
end
```
`do ... end` can be replaced with `{ ... }`

```ruby
Async {
	with Apify::Actor { |actor|
		input = actor.get_input
	}
}
```
