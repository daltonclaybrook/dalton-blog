---
layout: single
title:  "RxSwift+MVVM, a little at a time"
date:   2017-11-08 00:00:00 -0500
categories: rxswift
tags: rxswift mvvm
---
I was fortunate enough to be able to attend **[try! Swift NYC](https://academy.realm.io/conferences/try-swift-nyc-2017/)** this year, where I watched a number of interesting talks. Among my favorites were a forecast on machine ethics by [Paul Fenwick](https://twitter.com/pjf) and an interesting analysis of common bugs in Swift by [Carl Brown](https://twitter.com/CarlBrwn). I strongly encourage you to follow these guys and hear what they have to say. However, two events really stuck with me and helped open my mind to new ideas, resulting in a much-needed change to my everyday process. The first was a workshop on [RxSwift](https://github.com/ReactiveX/RxSwift), hosted by [Ash Furrow](https://twitter.com/ashfurrow), and the second was [a talk on MVVM](https://academy.realm.io/posts/try-swift-nyc-2017-nataliya-patsovska-mvvm-at-scale/) by [Nataliya Patsovska](https://twitter.com/nataliya_bg). This article assumes some basic knowledge of Reactive and Functional programming but is hopefully accessible to all developers in some capacity.

![An illustration of an electric eel. The ReactiveX logo is also an eel.](/assets/images/eel.png)

By day, I work on an app at Match called [BLK](https://itunes.apple.com/app/blk-the-dating-app-for-black-singles/id1253586891), where I have been using RxSwift fairly minimally. Up until recently, my use was mainly limited to networking code and model transformation. I knew I wasn’t using the framework to its full potential, but for some reason, I remained willfully ignorant of a few core features that I now feel make it truly powerful. Ash helped me discover some of these features and now I feel empowered to write code in a more Reactive style. Before we look at new code, however, I think it’s important to look at some of my old code in order to understand my problem:

{% gist 3ea4205ac65b9fe2e0824fa104a62456 %}

This is an example of an Observable sequence similar to others in my app. Almost all of my RxSwift code looks like this. Here, I’m calling fetchUsers() from an IBAction function, where I create a new Observable (an API request), transform the resulting data, then call *subscribe* on the sequence. For the sake of brevity, some code has been omitted from this and subsequent code samples. I have left it up to the reader to make inferences about (or simply ignore) the implementation details of some functions in this chain, such as mapModel(model:). You may have also noticed that this function contains side effects. Specifically, I’m showing/hiding a custom loading view, and reloading a table view. Finally, I have two functions for “configuring,” and handling the error case. This is [Imperative programming](https://en.wikipedia.org/wiki/Imperative_programming) behind a [Declarative](https://en.wikipedia.org/wiki/Declarative_programming) facade.

I’m still fairly new to RxSwift, but I’ve now learned to treat these kinds of subscriptions as a code smell. Let’s start by enumerating the potential problems with this code:

1. The function fetchUsers() is imperative. The IBAction has to call this function every time we want to fetch users. If the button tap could be represented as an Observable stream of events, would it be better to **bind** this stream to the fetcher?

1. Observables have a built-in function for handling side-effects called **do**. We could be using this function to show/hide the loading view, but would it be better if this Observable sequence didn’t care about UI at all?

1. There are plenty of cases where it makes perfect sense to call **subscribe** on an Observable, but this probably isn’t one of them. The ultimate purpose of this sequence is not to perform some side-effect, but rather to obtain a concrete model: an array of Users. Would it make more sense to **bind** this Observable to an Observer that needs the data?

Before we fix this code, I’d like to briefly digress in order to mention the talk by Nataliya. I have been reading about [MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) for a while now, and was aware of the pattern’s association with RxSwift, but had not decided to make the leap away from MVC yet on any of my projects. One of the themes of Nataliya’s presentation which resonated with me was the idea that, like most patterns, MVVM is helpful in some areas, and unhelpful in others, and that’s okay. Your project doesn’t have to be completely MVC or completely MVVM. In other words, MVVM is not an architecture.

![](/assets/images/mvvm-is-not-an-arch.png)

This idea helped me take the first step and start to implement MVVM a little at a time, and only where appropriate. I highly recommend you [watch this full talk](https://academy.realm.io/posts/try-swift-nyc-2017-nataliya-patsovska-mvvm-at-scale/) because it contains many helpful ideas, only one of which is discussed here.

So how could we use MVVM, and a more complete understanding of RxSwift, to improve the above code? First of all, I have to concede the following: Changes of the sort I am about to describe will not reduce the number of lines of code in your app, and are in fact likely to increase your line count. Some developers view LOC as the most important metric of code quality, and I typically feel it is a good one. However, I hope you will agree that extra lines constitute an acceptable sacrifice for what we hope to gain, namely:

1. Separation of concerns — our networking code should no longer interact directly with the UI layer.

1. Declarative code — we will describe *what* the program should do rather than *how* it should be done.

1. Isolation/minimization of side-effects — any side-effects should be represented as isolated Observable sequences rather than being embedded in callbacks alongside model updates.

First, we will discuss the main parts of my **View Model**. Instances of this type expose Observables for subscribing to changes on the model. Afterwards, we will look at how a view controller uses this type to bind UI elements.

{% gist 361cc27abe31e5e0082d7d99f317ca0d %}

The view model exposes three Observables: user, isLoading, and error. You’ll notice that these variables are generated from corresponding private members. These members can act as Observables *and* Observers, so we would not want to expose them directly. I won’t go into detail about the differences between Variable and PublishSubject, except to say that there are [several different types of Subjects](http://reactivex.io/documentation/subject.html), each with unique benefits.

{% gist 018cff89fb3e44b819e551035bcbc243 %}

Additionally, the view model contains one public function which transforms an Observable<Void> to Observable<[User]> by flat-mapping an API request Observable, then binds the result to the variable: usersVariable. You’ll notice this function also affects the variable isLoadingVariable by toggling its underlying value before and after the network request.

Now, how is this used?

{% gist ef8e7a8f3d52c32594a571af1479f8ee %}

Here we see four functions which bind UI elements to the view model. These functions are called from viewDidLoad(), which looks like this:

{% gist cfdb248cff417ecaf89a0adba7172621 %}

The first two binding functions use extensions from RxCocoa, which is a companion library to RxSwift and lives in the same repository. The extension for UITableView may not give you the exact level of customization you need, so don’t feel obligated to use this extension. It’s also easy to add Reactive extensions for your own types, as I have done with my custom LoadingView in the third function. The fourth and final function subscribes to the error stream on the view model. You can imagine that the handleError(_:) function probably shows an alert controller, or similar. Can you think of a way to show an error message that uses similar binding mechanisms as the first three functions?

---

Hopefully, through these changes, we have accomplished the goals of decoupling UI from networking/business logic, separating concerns, and isolating side-effects. Just as importantly, I hope we have improved our ability to rationalize about this code by describing it in terms of *what* the flow of data must affect, rather than *how* control flow should be directed. Thanks to MVVM, our view controller, and view model should now be more easily and independently testable, which is great.

There are plenty of great resources on the Internet for learning RxSwift. First and foremost, I recommend [ReactiveX.io](http://reactivex.io/), which is the specification that forms the basis for RxSwift and many other implementations, such as RxKotlin and RxJS. You can also tinker with different operators using [RxMarbles](http://rxmarbles.com/). If you are interested in learning how to make your RxSwift code even more functional, check out [how to feed ViewModels](https://medium.com/blablacar-tech/rxswift-mvvm-66827b8b3f10) by [Martin Moizard](https://twitter.com/martinmoizard).

I may still be in the honeymoon phase with RxSwift, but I think I can say it has changed the way I write code for the better. Now it’s time to refactor a little more.
