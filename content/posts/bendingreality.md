+++
title = 'Bending Reality - Lying to the client side and discovering API Authentication Bypass'
description = "A wierd glitch when refreshing the page of a webapp made me look into its potential cause. The end result? A really serious Authentication Bypass on the app's API."
tldr = "A wierd glitch when refreshing the page of a webapp made me look into its potential cause. After digging into it I discovered the glitch was caused by the fact that the app was loading its privileged view by default, and some miliseconds later, it made a request to the API to check the actual privileges of the user. Further on, this helped me discovered API endpoints that were accesible for unauthenticated users."
date = 2024-07-05
draft = false 
+++

## Glitches in the matrix

In Summer 2023 I had to use my university's webapp dedicated for the facultative courses choosing.
Right away from the first interaction with the website after logging in, something struck me.
Everytime I accessed / refreshed the page, for a fraction of a second it seemed that more buttons were displayed in the navbar.
This seemed interesting to look into, so I decided to look into it.

At first, I was expecting this to be some framework glitch - some delayed rendering or anything similar to this.
So, I started looking into the source code.
However, there was nothing interesting there.
Just the way a navbar should normally look.

I thought maybe there are some external resources loading with a delay so I fired up Burp and proxied the traffic.
Looking through the requests I saw many requests to the `/api/` endpoint made in the first miliseconds after refreshing the page.
One request seemed really interesting, and that was a GET request to the `/api/AcademicUser/GetRolesForUser` - so I decided to look into it.

## Going into the Rabbit Hole

The request looked like this.

```console
GET /api/AcademicUser/GetRolesForUser HTTP/2
Host: <redacted>
Authorization: <redacted>
...
```

Ok, nothing to pwn here... But how does the response look like?

```console
HTTP/2 200 OK
...

[
    "Student"
]
```

Could it be that the client-side renders a privileged view by default, and then updates it once it gets notified the current user is not privileged?
Let's intercept the response and fuzz it.

After fuzzing, I had a winner: `Admin`.
Everytime I replaced `Student` with `Admin`, I would get a privileged view of the application.

![student view of the app](/posts/imgs/student_view.png)
*Student view of the app*

![admin view of the app](/posts/imgs/admin_view.png)
*Admin view of the app*

![admin view of the app 2](/posts/imgs/admin_view2.png)
*Admin configurations*

## The Final Piece of the Puzzle

Viewing some buttons is something, but actually using them is something else.
The question was if I was limited to only getting a privileged view or I could execute privileged actions.
The response was that I could perform any action I was exposed to.

This lead me to an even more interesting hypothesis: if the server-side doesn't realize that I should not be able to access these API endpoints, does it even realize if the user making the request is authenticated or not?
The short answer: no.

## IMPACT

The impact of this vulnerability was quite big. Not only did I have access to data I shouldn't have access to, I could modify that data to.
Being able to change the attendence lists for the future courses is, in my opinion at least, a serious matter.
Of course, if someone used this to cause mayhem students would've probably noticed it and reported the issue, and the repartisation would've been remade.
However, if someone made small changes...

After discovering the vulnerability I reported it to the admin of this asset and they fixed the issue.
I retested it after some months and I must say they did a good job! (that is: there were no JWT vulns and the JWT was actually checked this time)

## CONCLUSIONS

The main takeaways I got from this were:

- Always secure your API endpoints, DUH!
- Sometimes, its worth looking into things that seem wierd to you even when you don't think you'll discover much from them.

Of course, those API endpoints could've been discovered by using a URL Fuzzer too, but harder and in a more noisy way.
Also, they had some custom names that I think most wordlists don't include.

PS: This writeup doesn't have a lot of pics and evidence as I didn't save many. At the time I didn't have this project (the blog) in mind. I only found a screen record I sent to the admin and took screenshots of it.
