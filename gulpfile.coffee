gulp = require 'gulp'
merge = require 'merge-stream'
rename = require 'gulp-rename'
pug = require 'gulp-pug'
sourcemaps = require 'gulp-sourcemaps'
frontmatter = require 'gulp-front-matter'
markdown = require 'gulp-markdown'
uglify = require 'gulp-uglify'
sass = require 'gulp-sass'
postcss = require 'gulp-postcss'
postcssImport = require 'postcss-import'
precss = require 'precss'
autoprefixer = require 'autoprefixer'
cssnano = require 'cssnano'
through = require 'through2'

renameDate = (dir=false) ->
	rename (path) ->
		path.dirname = (if dir then path.dirname else path.basename).replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)$/, "$1/$2/$4/")

# Pipes through a pug template with the given name
template = (name, vars={}) ->
	pugLib = require 'pug'

	through.obj (file, enc, cb) ->
		data = {
			contents: file.contents
			page: file.page or {}
			vars...
		}

		file.contents = new Buffer(pugLib.renderFile("templates/#{name}.pug", data), 'utf8')
		@push(file)
		cb()

collect = () ->
	all = []

	process = (file, enc, cb) ->
		all.push
			title: file.page.title
			description: file.page.description
			date: file.basename.replace(/^(\d\d\d\d)-(\d\d)-(\d\d).*$/, "$1-$2-$3")
			url: file.basename.replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)\.(html|md)$/, "/$1/$2/$4/")
			name: file.basename

		@push file
		cb()

	through.obj process, (cb) ->
		all.sort (a, b) -> if a.date < b.date then 1 else -1

		page = 0
		step = 5

		while page * step < all.length
			gulp.src(['content/index.pug'])
				.pipe(pug({
					locals: {
						all: all.slice(page * step, page * step + step),
						next: (page + 1) + 1
					}
				}))
				.pipe(rename("index#{if page then page + 1 else ''}.html"))
				.pipe(gulp.dest('build/'))

			page++

		cb()

gulp.task 'articles', ->
	md = gulp.src(['content/articles/*.md'])
		.pipe frontmatter
			property: 'page'
			remove: true
		.pipe markdown()

	html = gulp.src(['content/articles/*.html'])
		.pipe frontmatter
			property: 'page'
			remove: true

	articles = merge(md, html)
		.pipe template('article')
		.pipe renameDate()
		.pipe rename (path) -> path.basename = "index"

	assets = gulp.src(['content/articles/**/*.png', 'content/articles/**/*.pdf'])
		.pipe renameDate(true)

	merge(articles, assets)
		.pipe gulp.dest('build/')

gulp.task 'presentations', ->
	presentations = gulp.src(['content/presentations/*.pug'])
		.pipe frontmatter
			property: 'page'
			remove: true
		.pipe pug()
		.pipe template('presentation')

	assets = gulp.src(['content/presentations/**/*.png', 'content/presentations/**/*.jpg', 'content/presentations/**/*.svg'])
		.pipe renameDate(true)

	merge(presentations, assets)
		.pipe gulp.dest('build/presentations')

gulp.task 'pages', ->
	md = gulp.src(['content/pages/*.md'])
		.pipe frontmatter
			property: 'page'
			remove: true
		.pipe markdown()
		.pipe template('page')

	pages = gulp.src(['content/pages/*.pug'])
		.pipe frontmatter
			property: 'page'
			remove: true
		.pipe pug()

	index = gulp.src(['content/index.pug'])
		.pipe pug()

	pages = merge(md, pages, index)
		.pipe gulp.dest('build/')

gulp.task 'scripts', ->
	reveal = gulp.src(['node_modules/reveal.js/plugin/**'])
		.pipe gulp.dest('build/static/scripts/reveal/plugin/')

	scripts = gulp.src(['node_modules/reveal.js/js/reveal.js', 'static/scripts/**.js'])
		.pipe sourcemaps.init()
		.pipe uglify()
		.pipe sourcemaps.write('.')
		.pipe gulp.dest('build/static/scripts/')

	merge(reveal, scripts)

gulp.task 'images', ->
	gulp.src(['static/images/**'])
		.pipe gulp.dest('build/static/images/')

gulp.task 'styles', ->
	scss = gulp.src(['static/styles/**/*.scss'])
		.pipe sourcemaps.init()
		.pipe sass
			includePaths: ['node_modules', 'static/styles']

	css = gulp.src(['static/styles/**/*.css'])
		.pipe sourcemaps.init()

	merge(css, scss)
		.pipe(postcss([
			postcssImport({
				path: ['static/styles']
			}),
			precss(),
			autoprefixer(),
			cssnano()
		]))
		.pipe sourcemaps.write('.')
		.pipe gulp.dest('build/static/styles/')


tasks = [
	'articles', 'presentations', 'pages', 'styles', 'scripts', 'images'
]

gulp.task 'watch', gulp.parallel tasks, ->
	gulp.watch([
		'content/**/*.pug',
		'content/**/*.md',
		'content/**/*.html',
		'content/**/*.png',
		'content/**/*.jpg',
		'content/**/*.svg',
		'templates/*.pug'
	], gulp.parallel('presentations', 'articles', 'pages'))

	gulp.watch([
		'static/styles/**/*.css',
		'static/styles/**/*.scss'
	], gulp.series('styles'))

	gulp.watch([
		'static/images/**'
	], gulp.series('images'))


gulp.task 'default', gulp.parallel(tasks)
