
def test = /asdfasdfas dfasdf/

test

// good to go

def test1 = /asdfasdf$/

test

// still bad

///

test

/// 3 slashes works when there is a space or characters after it

def test2 = /sdfafdsfas$// // adding an additional slash resets things

test

///////

def test3 = $/asdfsdfaas$/$

test

/// now three slashes aren't working?

/$

test

/// '$//$' resets it I guess

def test4 = $/
asdf
sdfaas
/$

test

// multi-line dollar-slashy-quotes seem to work just fine

test
