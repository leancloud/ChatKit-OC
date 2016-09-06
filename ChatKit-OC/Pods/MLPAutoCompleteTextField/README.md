MLPAutoCompleteTextField
===================
>"We believe that every tap a user makes drains a tiny bit of their energy and patience. Typing is one of the biggest expenditures of both. What we needed was a textfield that could be completed in as few keystrokes as possible even for very long words. Thus _MLPAutoCompleteTextField_ was born."

![Alt text](/autocompleteDemo.png "Screenshot")|![Alt text](/keyboardDemo.png "Screenshot")

About
---------
_MLPAutoCompleteTextField_ is a subclass of _UITextField_ that behaves like a typical _UITextField_ with one notable exception: it manages a drop down table of autocomplete suggestions that update as the user types. Its behavior may remind you of Google's autocomplete search feature. As of version 1.3 there is also support for showing the autocomplete table as an accessory view of the keyboard.

####Example:
  >A user is required to enter a long and complicated chemical name into a textfield. With an autocomplete textfield, chemical names that closely match her entered string can be displayed as she types, and if she sees the chemical name she was thinking of she can select it and have it entered into the textfield automatically. This reduces the amount of typing she has to do and helps prevent errors. All this can occur within a single view and without the need for a search tableview controller.


Usage
---------
The goal for _MLPAutoCompleteTextField_ is to create an autocomplete textfield that is quick and easy to use, yet eminently customizable. To get a working _MLPAutoCompleteTextField_ instance, ensure you have done the following:

0. Add the _MLPAutoCompleteTextField_, _NSString+Levenshtein_, _MLPAutoCompleteDataSource_ and _MLPAutoCompleteTextFieldDelegate_ files into your project (should have six files in total). 

1. Have an _MLPAutoCompleteTextField_ instance allocated and initialized within some view.

2. Set the textfield's "autoCompleteDataSource" property to a valid object that implements the required methods of the _MLPAutoCompleteTextFieldDataSource_ protocol. Note that the method "autoCompleteTextField:possibleCompletionsForString:" is the method you use to return possible completions for the textfield's currently entered string. This method is expected to return either an array of _NSString_, or an array of objects conforming to the _MLPAutoCompletionObject_ protocol, or a mix of both. This method is also called asynchronously. 

3. _(Optional)_ Set the textfield's "autoCompleteDelegate" property to a valid object that implements the methods of the _MLPAutoCompleteTextFieldDelegate_ protocol for further customization options.

You should now have a working _MLPAutoCompleteTextField_ at this point. 


Autocomplete as a Keyboard Input Accessory
--------

As of version 1.3 of _MLPAutoCompleteTextField_, the autocomplete suggestions can be shown as a tableview that appears above the keyboard. To activate this feature, set the `autoCompleteTableAppearsAsKeyboardAccessory` property of the _MLPAutoCompleteTextField_ instance to `TRUE`.



Cocoapods
-------
CocoaPods are the best way to manage library dependencies in Objective-C projects.
Learn more at http://cocoapods.org

Add this to your podfile to add the MLPAutoCompleteTextField to your project.
`pod 'MLPAutoCompleteTextField', '~> 1.4'`



Notes
---------
Traditionally, you might have seen something similar to the _MLPAutoCompleteTextField_ implemented with something like a "search tableview controller". This approach has some limitations and boilerplate code which _MLPAutoCompleteTextField_ has strived to overcome. An _MLPAutoCompleteTextField_ is **not** meant to be a replacement for a search function, it is designed purely for quick string completion purposes.

The _MLPAutoCompleteTextField_ sorting of autocomplete strings is powered by the NSString+Levenshtein category extension written by Mark Aufflick (based loosely on a Levenshtein algorithm written by Rick Bourner). This algorithm basically calculates the edit distance between two strings (the number of changes required to turn one string into the other).

When a datasource passes an array of strings to an _MLPAutoCompleteTextField_, the textfield sorts the strings according to edit distance and displays this list of autocomplete suggestions.

**Used responsibly**, we hope the _MLPAutoCompleteTextField_ will open up new design possibilities for developers of all origins and skill levels. 

:D

Performance
---------
_MLPAutoCompleteTextField_ uses a multi-threaded approach to it's sorting of autocomplete strings so that the main thread is never blocked and the UI stays 100% responsive. 

Keep in mind that although you can pass an ungodly amount of strings in an array to the _MLPAutoCompleteTextField_ at once, sorting performance will suffer directly related to the number of strings you give (we're talking on the magnitude of thousands of strings). If performance is suffering, you should find ways to reduce the amount of strings you pass to the _MLPAutoCompleteTextField_ when it asks you for them. (For example, if you assume a user will always know the first letter of a word correctly, you may choose to only send an array of words that start with that letter or even close to that letter on the keyboard, rather than every single possible word you have). 


Known Issues
----------
+ Clear Color or Translucent textfields are a bit ugly at the moment.
+ Hide your autocomplete tableview (if its open) before rotating the view it's in, and then unhide after the rotation is done.


What to Expect in Future Updates
-----------

+ _Weighted Suggestions_: In some cases, there may exist multiple autocomplete strings that are all equally possible completions for the current entered incomplete string. In current versions, the user will simply have to keep typing a few more characters to further narrow down the autocomplete suggestions to float the most probable string to the top of the autocomplete list.

  However, in the future you can expect to see a sort of "weighting" or "ranking" system, which will allow you to favor some strings over others by assigning a number to them. Strings with higher weight will appear closer to the top of the list of autocomplete suggestions. So even though a group of strings are all equally possible completions for a given incomplete string, the ones with higher weight are deemed as being the "more probable" matches and will be sorted accordingly. 

  This should further reduce the number of characters a user has to type. 


+ _String Hiding_: If an autocomplete suggestion is of such poor quality that it has nothing in common at all with the user's currently entered string, then there may be a built in option to not display this suggestion at all. 

+ _Tokenized Bolding_: If a user has entered a string such as "Grate White Sha", and there is an autocomplete suggestion called "Great White Shark", then in the suggestion the word "Great" should be in bold, the word "White" should be regular, and the work "Shark" should have the "rk" bolded. This behaves more like Google's autocomplete. (A user can choose the reverse behavior too).

+ _Background Dimming_: When an autocomplete tableview menu is open, there should be an option to have the superview background dim a bit to keep the focus on the textfield and autocomplete suggestions.

License
--------
_MLPAutoCompleteTextField_ uses the MIT License:

>Copyright (c) 2013, Mainloop LLC

>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

>The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

The _NSString+Levenshtein_ category uses this license as stated in the .h and .m files:

>NSString+Levenshtein

>Copyright (c) 2009, Mark Aufflick
All rights reserved.

>Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

>* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of the Mark Aufflick nor the
names of contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

>THIS SOFTWARE IS PROVIDED BY MARK AUFFLICK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL MARK AUFFLICK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Credits
---------

_MLPAutoCompleteTextField_ was written by Eddy Borja, at Mainloop LLC.

_NSString+Levenshtein_ category extension was written by Mark Aufflick. 

If you make use of _MLPAutoCompleteTextField_, tell us about it! 
Feel free to leave comments, likes, hatemail, etc at hello@mainloop.us

