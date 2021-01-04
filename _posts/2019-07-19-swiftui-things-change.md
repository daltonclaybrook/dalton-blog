---
layout: single
title:  "SwiftUI: Things Change"
date:   2019-07-19 00:00:00 -0500
categories: swiftui
tags: swiftui swift wwdc
---
This year at WWDC 2019, Apple announced SwiftUI, a brand new way to build user interfaces on Apple devices. This framework is a complete departure from UIKit, and I — like many others — have been eager to experiment with this new tool.

SwiftUI allows you to describe your views using a *declarative* syntax as opposed to *imperative*. You specify which subviews are displayed in a view, which data those subviews rely on, and any *modifiers* to apply such as how they are positioned, sized, and styled. The following is an example of a simple view in SwiftUI.

{% gist 4655a37a9e1ea2ba87484338c1ac06e3 %}

> Note: [Much has already been written](https://swiftuihub.com/) about SwiftUI in the few weeks since the release of Xcode 11 beta 1. This post is not intended to be a complete introduction to SwiftUI.

Another key feature of SwiftUI — and the subject of this post — is the **BindableObject** protocol. [The docs](https://developer.apple.com/documentation/swiftui/bindableobject) offer the following brief summary of BindableObject:
> An object that serves as a view’s model.

Those who are familiar with [MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) can think of this object as the “view model.” Types that implement this protocol provide data that is needed by the view and provide a mechanism for informing the view when the data has changed. This mechanism is called a **Publisher** and is part of *yet another* brand new Apple framework called **Combine**. As you can see, there was no shortage of new frameworks at this year's conference!

I won’t go into specifics about Combine in this post, but if you are familiar with RxSwift — or [Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) in general — know this is the Apple-sanctioned framework for building Reactive apps for Apple platforms. [Shai Mishali](https://twitter.com/freak4pc) has published a handy “[Cheat Sheet](https://medium.com/gett-engineering/rxswift-to-apples-combine-cheat-sheet-e9ce32b14c5b)” to document analogs between RxSwift and Combine.

I mentioned before that a BindableObject informs a view when the model data has changed, but this is not strictly true anymore. Before the release of Xcode 11 beta 4, BindableObject declared the following property:

{% highlight swift %}
var didChange: Self.PublisherType { get }
{% endhighlight %}

BindableObjects were expected to emit an event on this Publisher *after* the model data had changed (as the past-tense property name implied). As of beta 4, however, this name — and subsequently the implication — has changed. It is now called willChange.

{% twitter https://twitter.com/luka_bernardi/status/1151581314564255744 %}

This may seem a bit confusing and unintuitive to you, as it does to me. The requirement of didChange is clear: events are Published after the model has changed to indicate that the view should be redrawn. Now with willChange, it’s not self-evidently clear exactly *when* events should be emitted on this Publisher. Should an event be emitted *synchronously* before the model is updated, such as from the willSet property observer of a state variable? Or perhaps it should emit even earlier, such as when the user signals intent to update state by, say, tapping a refresh button?

The following explanation is offered:

{% twitter https://twitter.com/luka_bernardi/status/1151633281982406656 %}

This lends support for the willSet strategy. Indeed, while offering a critique of another’s code, Luca provides explicit validation of this approach:

{% twitter https://twitter.com/luka_bernardi/status/1151636247858696193 %}

Others have speculated how this might be implemented under the hood, with one person [drawing an analogy](https://twitter.com/DevAndArtist/status/1151831772772089857) between the willChange Publisher and UIView.setNeedsLayout().

Based on my interpretation of this new information, I’ve implemented a [Property Wrapper](https://github.com/apple/swift-evolution/blob/master/proposals/0258-property-wrappers.md) which stores a model and publishes events at the appropriate times. The type is called **NextValue**:

{% gist d42dffe77122364802720cc4155567a2 %}

NextValue exposes a projectedValue property which is a Publisher. This property is accessed using the $ prefix and can be used as the willChange property on a BindableObject:

{% highlight swift %}
class ContentViewModel: BindableObject {
    @NextValue var model = MyModel(name: "Dalton")
    var willChange: NextValue<String>.Publisher { $model }
}
{% endhighlight %}

Things are changing with every new Xcode beta. This is just one example of the many additions, changes, and deprecations we have seen so far in these four beta versions. While at times these changes can be frustrating and confusing, it is motivating to see Apple frameworks engineers engaging in discussions with the Swift community and to see community members trading strategies, tools, and help with one another. These discussions undoubtedly lead to better APIs, better tooling, and a better community as a whole. Change is good.
