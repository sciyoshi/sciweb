# Polish Your Python With Rust

## Intro (5 mins)

*Thanks*

By a show of hands, how many of you have heard of Rust? And keep your hands up if you've used it before.

Why am I here at a Python conference speaking about a completely different language?

Alan Perlis, the first recipient of the Turing award, once said that "A language that doesn't affect the way you think about programming, is not worth knowing."

I've been programming in Python now for over 10 years, and when I first learned it, coming from C and C#, I was amazed by how expressive the language was and how good it felt to use.

(And it affected the way I thought about programming.)

In 2006, I released my first ever open source project called PyFacebook, which was the first Python client for Facebook's newly-released API. 

And as an enthusiastic but inexperienced programmer, I tried to create the best and cleverest code I could using all of the exciting dynamic features that Python offered. And I ended up with this:

	class Facebook(object):
		_methods = [
			'friends.get',
			'photos.createAlbum',
			#...
		]

		for method_name in _methods:
			signature = 'def ' + method_name.replace('.', '_') + '(self'

			... snip ...

			body += indent2 + 'return self._call_method("facebook.' + method_name + '"'

			definition = signature + body

			exec definition


Today I'm going to 



I love Python, but I think there are good reasons to learn a variety of languages, and Rust in particular is a language that I am really excited about because of a number of its unique features.

By the end of this talk, I hope you will have an appreciation of the novel concepts that Rust provides, as well as an understanding of how you can use it alongside Python to speed up your code.

### Background

Let me give you a bit of background about myself first.

For the past 10 years, I've been building web software using mainly Python and Javascript. For those keeping track, that means I've been using Python since version 2.3. I fell in love with the language as soon as I learned it, and it's stayed as my favorite language since. In a way, I feel like we've grown up together. In 2006 I released PyFacebook, my first open source project and the first Python client for Facebook's newly released API. Looking back at that code now, I can see how far I've come as a programmer. But Python has also come a long way in those 10 years - Pycon attendance has gone up 10-fold since then, and the language is better than ever. As you know, Python lets you express powerful ideas in a short amount of code, making it easy to write, and even easier to read and understand. Python today has a mature ecosystem, and powerful libraries for doing almost anything you can think of - machine learning, image processing, you name it, there's probably a way to do it in Python. And we have a passionate, diverse, and welcoming community, as shown by all of you here today.

So if I'm such an advocate for Python, why am I here talking to you about Rust? If Python can already do anything we need it to, what's the use of learning another language? I think there are a few good reasons.

First: because Python is a high-level language, it makes it easy to create working programs without understanding what's happening under the hood. You can follow a tutorial and create a Django app in an hour and have a website with a full admin interface. This is great and many people never need to go further than that. But it's hard to unlock your full potential as an engineer without a good conceptual idea of how programs run, the physical realities of computers, like memory layout and allocation, differences between stack and heap, and so on. Also, understanding algorithms and complexity theory helps you avoid writing code that breaks down at "web scale".

Second: there's times when Python falls short. We should all try to use the right tool for the job, and some jobs have performance requirements that Python can't meet. As an example, a recent blog post by Armin Ronacher from Sentry talks about how they re-built their sourcemap parsing component in Rust due to performance issues.

And lastly: it's fun! As an engineer I get excited by trying out new tools and technologies and applying them to real-world problems.

Programming languages can be a contentious issue, like text editors or indentation. If you're already familiar with Python and looking to go deeper, in my opinion Rust is one of the best to learn next. Even if you never write in Rust or any other language, the knowledge can transfer and help you in your work.

## About Rust (10 mins)

### Overview

Rust is a systems programming language that was announced by Mozilla in 2010. I first heard about Rust in 2014 when version 0.10 was announced. I took a brief look at it then, but when I looked at the tutorial I saw three different types of pointers, and saw that there were keywords being changed and removed, and thought to myself, maybe it's an interesting language but I don't have the time or see the value in learning it, so I didn't pay any more attention to it. Fast forward to August 2015, when I saw the release of Rust 1.0. I figured I should find out what the fuss was about - why so many people were excited about this language that to me as an newcomer just looked like a cleaned up version of C. So I sat down over a weekend to go through the tutorial, and my thinking changed completely. It had come a long way from the previous year, and what I saw was a really beautifully and cohesively designed language with a lot of really powerful features, a few of which I'll talk about today. What really sold me on Rust were two features in particular, the type system, and the concept of ownership and borrowing. I'll talk about these two in more detail, but first lets look at the basics of the syntax to get a feel for the language.

### Basics

Unlike Python, Rust is a compiled language and it uses the LLVM compiler infrastructure. LLVM is used by a number of different languages, meaning Rust can take advantage of a lot of the optimizations it provides. Rust's syntax is similar to C and C++. Let's take a look at a simple Hello World program.

	fn main() {
		let greet = "world";

		println!("Hello, {}!", greet);
	}

Here we can see that the `fn` keyword, which is like `def` in Python, is introducing a new function called `main`, which is the first function that gets called when the program runs. Next we see a new variable called `greet` being introduced with the `let` keyword. In Rust, all variables are immutable by default, meaning their value cannot be changed and the name cannot be reassigned, and we'll see why that's important shortly. If you do want a variable to be mutable, you have to explicitly write `let mut`.

The function then calls `println!`. The exclamation point indicates that this is actually a macro. I won't go into too much detail about macros today, but unlike the C preprocessor, which operates on text, Rust macros operate on the abstract syntax trees output by the parser. That means macros are much more powerful in Rust, and we'll see an example of that later when I talk about extending Python.

You'll notice we didn't specify a type for the `greet` variable. That's because most of the time, the Rust compiler is smart enough to be able to infer types for you. The exception is that types for functions must always be specified - Rust doesn't attempt to infer types across function boundaries.

Let's look at another example. Here's a function which takes a list of floating point numbers and returns their average. You can see that this function has a single argument called list, which is a reference to a slice of 64-bit floating point numbers, and returns a single floating number. In Rust, numeric types have an have an explicit size in bytes. It's not like Python where you can have arbitrary sized integers. Rust uses stack allocation by default, so variable sizes needs to be known at compile-time.

	fn avg(list: &[f64]) -> f64 {
		let mut total = 0.;

		for el in list {
			total += *el;
		}

		return total / list.len() as f64;
	}

The function then creates a mutable variable called `total`, and loops through each element in the slice, adding it to the total. It the returns the average by dividing by the length of the slice.

If you're familiar with C, you can think of this function as taking a pointer to an array of 64-bit floating point values. Iterating through the array gives you successive pointers to each element, which you need to dereference to get their value.

This is an example what's called the imperative style of programming, which simply means that the program is explicitly telling the computer what steps to take to achieve the outcome. And while this is the way that programming is normally taught, high-level languages often provide better ways of writing something like this. One drawback of this style of code is that it tends to be hard to parallelize, and the code is normally more verbose than it needs to be. This type of code would not be considered Pythonic - the idiomatic way to write an average function in Python would be something like this. --

	def avg(items):
		return sum(items) / len(items)

Not only is this easier to read, but by being more descriptive than prescriptive, it gives the interpreter or compiler freedom to optimize the underlying implementation as it sees fit. So let's see another way to do this in Rust:

	fn avg(list: &[f64]) -> f64 {
		let total: f64 = list.iter().sum();

		return total / list.len() as f64;
	}

Here we are converting the slice into an iterator, and asking for its sum as a floating point value. This code returns the same result as before, but it's shorter and easier to understand. There's a third way we could right this function, and that is by using a fold operator, which might be more familiar to some of you as reduce, the operator that was removed in Python 3. Here's how that would look:

	fn avg(list: &[f64]) -> f64 {
		let total: f64 = list.iter().fold(0., |a, b| a + b);

		return total / list.len() as f64;
	}

This is saying to start with the value 0 and successively add items from the list. The new syntax is called a closure, which is similar to a lambda in Python, and this represents the binary operation of addition. One of Rust's most compelling features is that is has these first-class functions, meaning you can pass functions as arguments or use them as return values, so it feels like a functional language. But what makes Rust unique here is that in many of the typical scenarios where you would use closures, the compiler is actually able to optimize away these calls to nothing. That means zero allocations and zero runtime indirection. In Python, unless you have a good JITting interpreter, this style of code normally has significant performance overhead. But in Rust, these all run at the same speed, and to prove this to you, I benchmarked all three versions against arrays of a million numbers:

	λ cargo bench
	    Finished release [optimized] target(s) in 0.0 secs
	     Running target/release/deps/bench-4033a5e20d93d9a3

	running 3 tests
	test tests::bench_avg      ... bench:   1,016,120 ns/iter (+/- 168,020)
	test tests::bench_avg_fold ... bench:   1,008,394 ns/iter (+/- 166,063)
	test tests::bench_avg_sum  ... bench:   1,002,382 ns/iter (+/- 204,337)

This is an example of Rust's philosophy of "zero-cost abstractions". 

### Type System

So now that you hopefully have a basic idea of what Rust code looks like, I want to talk about my two favorite features in Rust.


	#include <stdio.h>

	static char *hello = "Hello world!";

	int main() {
		hello[0] = 'C';

		printf("%s\n", hello);
	}

One of my favorite features of Rust is its strong type system. 

Traits

### Ownership and Borrowing



## Extending Python (8 mins)

rust-cpython

cffi

### Limitations

## Conclusion (2 mins)

