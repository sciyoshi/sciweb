# Polish Your Python With Rust

## Intro (2 mins)

*Thanks*

By a show of hands, how many of you have heard of Rust? And keep your hands up if you've used it before.

Why am I here at a Python conference speaking about a completely different language?

Alan Perlis, the first recipient of the Turing award, once said that "A language that doesn't affect the way you think about programming, is not worth knowing."

This rings true for me. Rust is a language which has really changed my way of thinking. It's a systems language that combines the speed and control of C with the safety and expressive power of higher level languages like Python and Haskell.

Today I'd like to talk about why, of all the existing languages, Rust is the one I think is most worth knowing. I'll give you a short introduction to the Rust programming language, and talk in a bit more detail about two of its features in particular that I'm really excited about - its type system, and the concept of ownership. At the end, I'll show how you can use Rust in combination with Python to speed up critical parts of your code.

## Why Rust? (5 mins)

### Background

Let me start with a bit of background.

I've been programming in Python now for over 10 years, mainly building web software. When I first learned it, coming from C and C#, I was amazed by how expressive the language was and how good it felt to use. I fell in love with Python as soon as I learned it, and it's stayed as my favorite language since.

Today, Python is better than ever

But Python has also come a long way in those 10 years since version 2.3 - Pycon attendance has gone up 10-fold since then. As you know, Python lets you express powerful ideas in a short amount of code, making it easy to write, and even more importantly easier to read and understand. Python today has a mature ecosystem, and powerful libraries for doing almost anything you can think of - machine learning, image processing, you name it, there's probably a way to do it in Python. And we have a passionate, diverse, and welcoming community, as shown by all of you here today.


So if I'm such an advocate for Python, why am I here talking to you about Rust? If Python can already do anything we need it to, what's the use of learning another language? I think there are a few good reasons.

First: because Python is a high-level language, it makes it easy to create working programs without understanding what's happening under the hood. You can follow a tutorial and create a Django app in an hour and have a website with a full admin interface. This is great and many people never need to go further than that. But it's hard to unlock your full potential as an engineer without a good conceptual idea of how programs run, the physical realities of computers, like memory layout and allocation, differences between stack and heap, and so on. Also, understanding algorithms and complexity theory helps you avoid writing code that breaks down at "web scale".

Second: there's times when Python falls short. We should all try to use the right tool for the job, and some jobs have performance requirements that Python can't meet. As an example, a recent blog post by Armin Ronacher from Sentry talks about how they re-built their sourcemap parsing component in Rust due to performance issues.

And lastly: it's fun! As an engineer I get excited by trying out new tools and technologies and applying them to real-world problems.

Programming languages can be a contentious issue, like text editors or indentation. If you're already familiar with Python and looking to go deeper, in my opinion Rust is one of the best to learn next. Even if you never write in Rust or any other language, the knowledge can transfer and help you in your work.

(REWORK THIS PARAGRAPH?)

I first started hearing about Rust in 2014. And at the time I was mostly working on large Python and Javascript codebases that unfortunately didn't have much test coverage. We would constantly see errors in our server logs that looked like [THIS]. Granted, Python 3 has helped with the Unicode issue, but the experience of seeing these types of errors in production made me really appreciate the value of things like static type systems. 

The other thing I learned was that just because you're able to do something
doesn't mean it's a good idea. In 2006, I released my first ever open source project called PyFacebook, which was the first Python client for Facebook's newly-released API. 

And as an enthusiastic but inexperienced programmer, I tried to create the best and cleverest code I could using all of the exciting dynamic features that Python offered. And I ended up with this:

Looking back at that code now, I can see how far I've come as a programmer.


Rust was originally announced by Mozilla in 2010. I first heard about Rust in 2014 when version 0.10 was announced. I took a brief look at it then, but when I looked at the tutorial I saw three different types of pointers, and saw that there were keywords being changed and removed, and thought to myself, maybe it's an interesting language but I don't have the time or see the value in learning it, so I didn't pay any more attention to it. Fast forward to August 2015, when I saw the release of Rust 1.0. I figured I should find out what the fuss was about - why so many people were excited about this language that to me as an newcomer just looked like a cleaned up version of C. So I sat down over a weekend to go through the tutorial, and my thinking changed completely. It had come a long way from the previous year, and what I saw was a really beautifully and cohesively designed language with a lot of really powerful features, a few of which I'll talk about today.





Rust provides memory safety guarantees, data-race freedom, and high-level abstractions while still offering efficiency and low-level control.

Python is a garbage collected language, and it uses reference counting to determine when objects are no longer accessible and can be freed. Rust, on the other hand, doesn't have a garbage collector, but it is still able to manage memory automatically!




First lets look at the basics of the syntax to get a feel for the language.

## Intro to Rust (5 mins)

Unlike Python, Rust is a compiled language and it uses the LLVM compiler infrastructure. LLVM is used by a number of different languages, meaning Rust can take advantage of a lot of the optimizations it provides. Rust's syntax is similar to C and C++. 

Let's take a look at a simple Hello World program.

Here we can see that the `fn` keyword, which is like `def` in Python, is introducing a new function called `main`, which is the first function that gets called when the program runs. Next we see a new variable called `greet` being introduced with the `let` keyword. In Rust, all variables are immutable by default, meaning their value cannot be changed and the name cannot be reassigned, and we'll see why that's important shortly. If you do want a variable to be mutable, you have to explicitly write `let mut`.

The function then calls `println!`. The exclamation point indicates that this is actually a macro. I won't go into too much detail about macros today, but unlike the C preprocessor, which operates on text, Rust macros operate on the abstract syntax trees output by the parser. That means macros are much more powerful in Rust, and we'll see an example of that later when I talk about extending Python.

You'll notice we didn't specify a type for the `greet` variable. That's because most of the time, the Rust compiler is smart enough to be able to infer types for you. The exception is that types for functions must always be specified - Rust doesn't attempt to infer types across function boundaries.

Let's look at another example. Here's a function which takes a list of floating point numbers and returns their average. You can see that this function has a single argument called list, which is a reference to a slice of 64-bit floating point numbers, and returns a single floating number. In Rust, the width of numeric types is explicit, and most types need to have a known size at compile time. It's not like Python where you can have arbitrary sized integers. Rust uses stack allocation by default, so variable sizes needs to be known at compile-time.

The function then creates a mutable variable called `total`, and loops through each element in the slice, adding it to the total. It the returns the average by dividing by the length of the slice. Notice that there's no explicit `return` keyword - in Rust, the value of the last expression in a function is automatically returned.

If you're familiar with C, you can think of this function as taking a pointer to an array of 64-bit floating point values. Iterating through the array gives you successive pointers to each element, which you need to dereference to get their value.

This is an example what's called the imperative style of programming, which simply means that the program is explicitly telling the computer what steps to take to achieve the outcome. And while this is the way that programming is normally taught, high-level languages often provide better ways of writing something like this. One drawback of this style of code is that it tends to be hard to parallelize, and the code is normally more verbose than it needs to be. This type of code would not be considered Pythonic - the idiomatic way to write an average function in Python would be something like this. --

Not only is this easier to read, but by being more descriptive than prescriptive, it gives the interpreter or compiler freedom to optimize the underlying implementation as it sees fit. So let's see another way to do this in Rust:

Here we are converting the slice into an iterator, and asking for its sum as a floating point value. This code returns the same result as before, but it's shorter and easier to understand.

There's a third way we could right this function, and that is by using a fold operator, which might be more familiar to some of you as reduce, the operator that was removed in Python 3. Here's how that would look:

This is saying to start with the value 0 and successively add items from the list. The new syntax is called a closure, which is similar to a lambda in Python, and this represents the binary operation of addition. One of Rust's most compelling features is that is has these first-class functions, meaning you can pass functions as arguments or use them as return values, so it feels like a functional language. But what makes Rust unique here is that in many of the typical scenarios where you would use closures, the compiler is actually able to optimize away these calls to nothing. That means zero allocations and zero runtime indirection. In Python, unless you have a good JITting interpreter, this style of code normally has significant performance overhead. But in Rust, these all run at the same speed, and to prove this to you, I benchmarked all three versions against arrays of a million numbers:

This is an example of Rust's philosophy of "zero-cost abstractions". 

## Type System (5 mins)

So now that you hopefully have a basic idea of what Rust code looks like, I want to talk about my two favorite features in Rust, the ones that I'm really excited about. The first is Rust's type system.

Now from my observation over over the past few years, I feel like there's been a trend of languages moving towards strong or stronger typing. That's the case for Python - the 2016 PyCon keynote was an announcement of Mypy, a type-checking tool for Python 3.5. That's also been the case in the Javascript world, where languages like TypeScript and Elm, and the Flow type-checker from Facebook have all been gaining popularity. The appeal of strong type checking is that you can prevent a large class of runtime errors from ever happening.

Rust provides all of the basic types you would expect, and the standard library has a number of solid container implementations.

Rust fixes a number of problems in C, like using numbers or pointers as booleans.

Talk about structs

*talk about nulls*

### Traits

Rust's type system will seem a bit unfamiliar at first if you're used to object-oriented languages. In OOP, classes and inheritance are a means of achieving code reuse and polymorphism. But Rust doesn't have classes, and it instead achieves these using a different concept called traits.

Traits are essentially a collection of methods. They are conceptually similar to interfaces in C# and Java, but serve a much more fundamental role. Traits can be used as markers of specific functionality, for overloading operators, for bounds on generic functions, and even for dynamic dispatch.

Let's look at an example. In Python, when you declare a class, the methods are defined directly within its body and are associated to it.

In Rust, method and trait implementations are defined separately from the type itself. So first we would declare a type ()

You can think of traits as protocols or interfaces that types can implement to indicate behavior.


## Ownership and Borrowing (5 mins)

I mentioned before that Rust guarantees memory safety and prevents data races, and the way it does that is through the concept of ownership.

Variable bindings in Rust have ownership of what they refer to. When a binding goes out of scope, the owned resource is freed.




## Extending Python (5 mins)



rust-cpython

cffi

### Limitations

## Conclusion (2 mins)

