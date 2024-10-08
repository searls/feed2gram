# feed2gram - Syndicate your site's photos, videos, and carousels to Instagram

**feed2gram is for automating Instagram posts, for posting to Threads, see
[feed2thread](https://github.com/searls/feed2thread)**

I've joined the [POSSE](https://indieweb.org/POSSE) and publish as much as I can
to [justin.searls.co](https://justin.searls.co) and syndicate it elsewhere.  I'm
already using [feed2toot](https://feed2toot.readthedocs.io/en/latest/) to
cross-post to Mastodon, but for my [image
posts](https://justin.searls.co/shots/) in particular, I wanted to cross-post
them to Instagram, so I made this thing that reads from an Atom XML feed and
generates Instagram posts. It's meant to be run on a schedule (e.g.
[cron](https://en.wikipedia.org/wiki/Cron) job) to regularly check the feed, and
does its best to avoid double-posts by keeping track of post URLs that have
already been processed

## Prerequisites

First step: take a deep breath and prepare to budget half a day of frustration
to this. The number of hoops you need to jump through to post to Instagram are
myriad:

1. [Convert your Instagram account to a
professional](https://business.instagram.com/getting-started#) (either "creator"
or "business" types work with this gem)
2. Create a Facebook Page with your Facebook account and [link it to your
Instagram account](https://help.instagram.com/570895513091465)
3. [Create a Facebook developer account](https://developers.facebook.com/docs/development/register/)
4. [Create a Facebook app](https://developers.facebook.com/docs/development/create-an-app/) and grant it these permissions (you don't actually need all of these but figuring out the exact set of them is a pain and they sure seem to change frequently, so YMMV):
    * `instagram_basic`
    * `instagram_manage_comments`
    * `instagram_manage_insights`
    * `instagram_content_publish`
    * `business_management`
    * `pages_show_list`
    * `pages_read_engagement`
    * `pages_manage_metadata`
    * `pages_manage_posts`
    * `public_profile`
5. Generate an access token for yourself; the easiest way is probably the [Graph API Explorer tool](https://developers.facebook.com/tools/explorer/)
6. With that access token, (set here to a `FACEBOOK_ACCESS_TOKEN` env var), find the right Facebook Page ID you linked to your Instagram account. You can `curl` it like this: `curl -X GET  "https://graph.facebook.com/v18.0/me/accounts?access_token=$FACEBOOK_ACCESS_TOKEN"` (I recommend piping the results to [jq](https://jqlang.github.io/jq/), so install that and tack on `| jq`)
7. With that Facebook Page ID (set here to `FACEBOOK_PAGE_ID), find your Instagram account ID. Here's a curl command: `curl -X GET  "https://graph.facebook.com/v18.0/$FACEBOOK_PAGE_ID?fields=instagram_business_account&access_token=$FACEBOOK_ACCESS_TOKEN"`
8. Note down your access token, your Instagram account ID, your App ID, and your App Secret (the last two can be retrieved from the "App Settings" -> "Basic" from [your app's dashboard](https://developers.facebook.com/apps/?show_reminder=true))
9. You're ready to read the [Instagram Graph API](https://developers.facebook.com/docs/instagram-api/overview), [Getting Started doc](https://developers.facebook.com/docs/instagram-api/getting-started), and the [Content Publishing Guide](https://developers.facebook.com/docs/instagram-api/guides/content-publishing)

## What this gem does

To get an idea of what this gem is doing under the hood, namely it will:

1. Trade whatever access token you hand it for a [refreshed long-lived token](https://developers.facebook.com/docs/facebook-login/guides/access-tokens/get-long-lived), and then save that updated/refreshed token to your feed2gram configuration (long-lived tokens expire after 60 days and must be refreshed before they expire or else you need to generate a new one; keep this in mind if you don't plan to run `feed2gram` continuously or if the configuration file isn't writable)
2. Load your Atom feed and scan it for entries that contain a `<figure>` element (only the first `<figure>` will be read). See notes on [formatting your feed](#formatting-your-atom-feeds-html)
3. For each such entry, [create an image container](https://developers.facebook.com/docs/instagram-api/guides/content-publishing/#step-1-of-2--create-container) (this is when the Facebook backend downloads the image and processes it)
4. If the `<figure>` contains multiple `<img>` tags, create a carousel container that references all the subordinate image containers
5. Once the container is created, [publish it](https://developers.facebook.com/docs/instagram-api/guides/content-publishing/#step-2-of-2--publish-container) to Instagram
6. Success or failure, save a cache entry that indicates the URL of the entry was processed so we don't repeatedly post (or fail to post) the same thing over and over again

## Install and usage

```
$ gem install feed2gram
```

Next, create a configuration file in YAML to tell feed2gram everything it needs
to run. Make sure this file is writable, as the gem will refresh the facebook
access token on each run:

```yaml
feed_url: https://example.com/photos.xml
facebook_app_id: 1234
facebook_app_secret: 5678
instagram_id: 9000
access_token: EAADXD
```

If the above were saved as `my_feed2gram.yml`, we could then run the app from
the command line:

```
$ feed2gram --config my_feed2gram.yml
```

In addition to overwriting the `access_token` in your configuration
file, a `my_feed2gram.cache.yml` will also be created (or updated) in the same
directory. This file is used internally by feed2gram to keep track of which
entry URLs in the atom feed have been processed and can be ignored on the next
run.

## Options

For available options, run `feed2gram --help`:

```
$ feed2gram --help
Usage: feed2gram [options]
  --config PATH        Path of feed2gram YAML configuration (default: feed2gram.yml)
  --cache-path PATH    Path of feed2gram's cache file to track processed entries (default: feed2gram.cache.yml)
  --limit POST_COUNT   Max number of Instagram posts to create on this run (default: unlimited)
  --skip-token-refresh Don't attempt to exchange the access token for a new long-lived access token
  --populate-cache     Populate the cache file with any posts found in the feed WITHOUT posting them to Instagram
```

## Environment variables

These environment variables can be set to augment the gem's behavior:

* `SECONDS_PER_UPLOAD_CHECK` - when uploading video, feed2gram must wait until
the [status code](https://tiagogrosso.github.io/instagram-graph-api-lib/enums/CONTAINER_STATUS_CODE.html) on the media indicates it is published. This variable determines how many seconds to wait between each check (defaults to `30` seconds). Shortening this value can lead to hitting one's hourly rate limit
* `MAX_UPLOAD_STATUS_CHECKS` - how many status checks to perform before giving up on a piece of media and calling the post failed. Unfortunately, Facebook's servers can take anywhere from 15 seconds to 15 hours to download and process even trivially small videos, so GLHF (defaults to `100` attempts)
* `RETRIES_AFTER_UPLOAD_TIMEOUT` - because Facebook's servers will so often hang and fail to download videos (even when you
set the timeout to absurd lengths like 20 hours, it'll still report `IN_PROGRESS`), it may be necessary to retry after timeout. (defaults to `5` retries)

## Formatting your Atom feed's HTML

feed2gram uses the first `<figure>` element to generate each Instagram post. That `<figure>` can contain one or more `<img>` tags and one `<figcaption>` tag, which will be used as the post's image(s) and caption, respectively.

Some things to keep in mind:

* A `<figure>` may specify a `data-post-type` with a value of `reels`, `stories`, or `post` (if unspecified, the type defaults to `post`)
  * If `data-post-type` is set to `stories` or `reels`, exactly one image or video must be included. If `post`, then multiple (up to ten) images and videos can be included and will publish as a carousel post
  * Posting stories (i.e. `<figure data-post-type="stories">`) requires a _business_ account, not a creator one (in which case a, "the user is not an Instagram Business," error will be returned)
* If one `<img>` tag is present, a single photo post will be created. If there are more, a [carousel post](https://developers.facebook.com/docs/instagram-api/guides/content-publishing/#carousel-posts) will be created
* Because Facebook's servers actually _download your image_ as opposed to receiving them as uploads via the API, every `<img>` tag's `src` attribute must be set to a publicly-reachable, fully-qualified URL
* To post videos, stories, or reels, set the `data-media-type` attribute on the `<img>` tag to `video` or `image` (a media type of `image` will be assumed by default if left unspecified). Note that while `image` and `video` media may be interspersed throughout a carousel
* For video (reel) posts containing a single video, you can set `data-cover-url` on the `<img>` tag to a publicly-available URL and the Instagram API will use it as a custom thumbnail for the reel
* For carousel posts, the aspect ratio of the first image determines the aspect ratio of the rest, so be mindful of how you order the images based on how you want them to appear in the app
* Only one caption will be published, regardless of whether it's a single photo post or a carousel
* The caption limit is 2200 characters, so feed2gram will truncate it if necessary
* The API is pretty strict about media file formats, too, so you may wish to preprocess images and videos to avoid errors in processing:
  * Images can't be more than 8MB and must be standard-issue JPEGs
  * Videos are even stricter (best to just [read the docs](https://developers.facebook.com/docs/instagram-api/reference/ig-user/media#creating), including this bit on [reels](https://developers.facebook.com/docs/video-api/guides/reels-publishing)). Videos that appear in carousels seem to have additional no-longer-documented restrictions (in my testing, 9:16 videos routinely failed but 16:9, 1:1, 4:3, and 3:4 succeeded)

Here's an example `<entry>` from my blog feed:

```xml
<entry>
  <id>http://localhost:1313/shots/2023-10-17-08h04m28s/</id>
  <title type="text">A tale of artificial intelligence in four acts</title>
  <link href="http://localhost:1313/shots/2023-10-17-08h04m28s/" rel="alternate" type="text/html" />
  <author>
      <name>Justin Searls</name>
      <email>website@searls.co</email>
  </author>
  <published>2023-10-17T12:04:28+00:00</published>
  <updated>2023-10-17T12:04:28+00:00</updated>

  <content type="html"><![CDATA[
<figure>
  <img src="/shots/2023-10-17-08h04m08s-c913ad8.jpeg"/>
  <img src="/shots/2023-10-17-08h04m08s-79dbb2d.jpeg"/>
  <img src="/shots/2023-10-17-08h04m08s-8421af6.jpeg"/>
  <img src="/shots/2023-10-17-08h04m08s-b172e07.jpeg"/>
  <figcaption>
I was wondering if I should keep dragging my hacky little OpenAI API wrapper class from script to script, so:

1. Search [rubygems.org](https://rubygems.org) for &#34;gpt&#34;
2. Find one called `chat_gpt` described as &#34;This is OpenAI&#39;s ChatGPT API wrapper for Ruby&#34;
3. Click the &#34;Homepage&#34; link
4. The code repository is archived and contains the disclaimer &#34;NOTE this code was written by ChatGPT and may not work&#34;

Great job, everyone.

See more at http://localhost:1313/
</figcaption>
</figure>
]]></content>
</entry>
```

## Running continuously with Docker

We publish a Docker image [using GitHub
actions](https://github.com/searls/feed2gram/blob/main/.github/workflows/main.yml)
tagged as `latest` for every new commit to the `main` branch, as well as with a
release tag tracking every release of the gem on
[rubygems.org](https://rubygems.org/gems/feed2gram). The images are hosted [here on GitHub's
container
registry](https://github.com/searls/feed2gram/pkgs/container/feed2gram)


You can also use Docker to run this on your own automation platform like Proxmox or Kubernetes.

```
$ docker run --rm -it \
  -v ./your_config_dir:/srv/config
  ghcr.io/searls/feed2gram
```

To configure the container, there are just four things to know:

1. A volume containing your configuration and cache files must be mounted to `/config`
2. By default, feed2gram will run with `--config /config/feed2gram.yml`, but you can
customize this by configuring the command value as needed
3. By default, feed2gram is run as a daemon every 60 seconds, and that duration can be overridden
by setting a `SLEEP_TIME` environment variable to the number of seconds you'd like
to wait between runs
4. If you'd rather run `feed2gram` as ad hoc as opposed to via the included daemon
(presumably to handle scheduling it yourself), simply change the entrypoint to
`/srv/exe/feed2gram`

### Running the docker image specifically on your Synology NAS

I run this on my [Synology DS 920+](https://www.pcmag.com/reviews/synology-diskstation-ds920-plus), using the [DSM's Container Manager](https://www.synology.com/en-global/dsm/feature/container-manager) app.

There are just a few things to know to set this up:

At the time of this writing, the `Action > Import > Add from URL` feature of the Container Manager's
"Image" tab does not support GitHub Container Registry URLs. However, if you connect [via SSH](https://kb.synology.com/en-my/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet):

```
$ sudo -s
# Enter your user password.
$ docker pull ghcr.io/searls/feed2gram:latest
```

Once downloaded, the image will appear in the app. From there, select
`ghcr.io/searls/feed2gram`, hit Run, and complete the wizard, setting any custom
command line flags (once the container is created, this cannot be edited), as
well as choosing a location to mount the `/config` volume and setting a
`SLEEP_TIME` environment variable (these can be changed after the fact).

## Frequently Asked Questions

### Why didn't my post show up?

Look at your cache file (by default, `feed2gram.cache.yml`) and you should see
all the Atom feed entry URLs that succeeded, failed, or were (by the `--populate-cache` option) skipped. If you don't see the error in the log, try
removing the relevant URL from the cache and running `feed2gram` again.

### What are the valid aspect ratios for images?

If you're seeing an embedded API error like this one:

```
The submitted image with aspect ratio ('719/194',) cannot be published. Please submit an image with a valid aspect ratio.
```

It means your photo is too avant garde for a mainstream normie platform like
Instagram. Make sure all images' aspect ratios are between 4:5 and 1.91:1 or
else the post will fail.

### How do I test this thing? It's not allowing any of my videos

The hardest thing about testing this (other than the _everything about it_) is
that the API is way stricter about video formats than the app is, since the app
processes them for you. Here are two example videos the API _will accept_ from
the [official example repo](https://github.com/fbsamples/reels_publishing_apis/tree/main/insta_reels_publishing_api_sample):

* https://static.videezy.com/system/resources/previews/000/014/045/original/30_seconds_digital_clock_display_of_sixteen_segments.mp4
* https://static.videezy.com/system/resources/previews/000/032/359/original/MM008645___BOUNCING_FRUIT_009___1080p___phantom.mp4
