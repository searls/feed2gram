## [1.2.0]

* Add support for the `cover_url` property for reel posts by way of a
`data-cover-url` attribute on the `<img>` tag of single-video posts..

## [1.1.0]

* Add support for videos and stories, including:
  * single-video posts (which post as reels), by setting `data-media-type=video`
  attribute on a feed entry's `<figure>`'s only `<img>` child
  * single-image and single-video stories, by setting `data-post-type=stories`
  attribute on a feed entry's `<figure>` element
  * carousels that contain videos and photos by setting `data-media-type=video`
  attribute on each `<img>` tag that contains a video
* Print much more granular feedback when publishing and in verbose mode
* When all posts are filtered out from the cache, say so (when verbose) and
don't update the cache file needlessly

## [1.0.0]

* Simplify the docker build
* Call it 1.0

## [0.0.4]

* Optimize the size of the Docker image (about 85% reduction)

## [0.0.3]

* Fix the `--populate-cache` so that all entries are marked `skipped`
* Include a `bin/daemon` script
* Ship a Dockerfile to build an image that can run feed2gram on a schedule

## [0.0.2] - 2023-10-29

- Initial release
