"use strict";

let gulp = require('gulp');
let merge = require('merge-stream');
let rename = require('gulp-rename');
let pug = require('gulp-pug');
let sourcemaps = require('gulp-sourcemaps');
let frontmatter = require('gulp-front-matter');
let markdown = require('gulp-markdown');
let uglify = require('gulp-uglify');
let postcss = require('gulp-postcss');
let postcssImport = require('postcss-import');
let precss = require('precss');
let autoprefixer = require('autoprefixer');
let cssnano = require('cssnano');
let through = require('through2');

// Pipes through a pug template with the given name
let template = (name, vars={}) => {
	let pug = require('pug');

	return through.obj(function(file, enc, cb) {
		let data = Object.assign({
			contents: file.contents,
			page: file.page || {}
		}, vars);
		file.contents = new Buffer(pug.renderFile(`templates/${name}.pug`, data), 'utf8');
		this.push(file);
		cb();
	});
};

let collect = () => {
	let all = [];

	return through.obj(function(file, enc, cb) {
		all.push({
			title: file.page.title,
			description: file.page.description,
			date: file.basename.replace(/^(\d\d\d\d)-(\d\d)-(\d\d).*$/, "$1-$2-$3"),
			url: file.basename.replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)\.(html|md)$/, "/$1/$2/$4/"),
			name: file.basename
		});

		this.push(file);
		cb();
	}, function(cb) {
		all.sort((a, b) => a.date < b.date ? 1 : -1);

		let page = 0;
		let step = 5;

		while (page * step < all.length) {
			gulp.src(['content/index.pug'])
				.pipe(pug({
					locals: {
						all: all.slice(page * step, page * step + step),
						next: (page + 1) + 1
					}
				}))
				.pipe(rename(`index${page ? page + 1 : ''}.html`))
				.pipe(gulp.dest('build/'))

			page++;
		}

		cb();
	});
};

gulp.task('articles', () => {
	let md = gulp.src(['content/articles/*.md'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}))
		.pipe(markdown());

	let html = gulp.src(['content/articles/*.html'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}));

	let articles = merge(md, html)
		.pipe(collect())
		.pipe(template('article'))
		.pipe(rename((path) => {
			path.dirname = path.basename.replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)$/, "$1/$2/$4/");
			path.basename = "index";
		}));

	let assets = gulp.src(['content/articles/**/*.png', 'content/articles/**/*.pdf'])
		.pipe(rename((path) => {
			path.dirname = path.dirname.replace(/^(\d\d\d\d)-(\d\d)-(\d\d)-(.*)$/, "$1/$2/$4/");
		}));

	return merge(articles, assets)
		.pipe(gulp.dest('build/content/articles'));
});

gulp.task('presentations', () =>
	gulp.src(['content/presentations/*.pug'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}))
		.pipe(pug())
		.pipe(template('presentation'))
		.pipe(gulp.dest('build/content/presentations/'))
);

gulp.task('scripts', () =>
	gulp.src(['node_modules/reveal.js/js/reveal.js', 'static/scripts/**.js'])
		.pipe(sourcemaps.init())
		.pipe(uglify())
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('build/static/scripts/'))
);

gulp.task('styles', () =>
	gulp.src(['static/styles/**.css'])
		.pipe(sourcemaps.init())
		.pipe(postcss([
			postcssImport(),
			precss(),
			autoprefixer(),
			cssnano()
		]))
		.pipe(sourcemaps.write('.'))
		.pipe(gulp.dest('build/static/styles/'))
);

gulp.task('watch', gulp.parallel('presentations', 'scripts', 'styles', 'articles', () => {
	gulp.watch(['content/**/*.pug', 'content/**/*.md', 'content/**/*.html', 'templates/*.pug'], gulp.parallel('presentations', 'articles'));
	gulp.watch(['static/styles/**/*.css'], gulp.series('styles'));
	//gulp.watch(['static/scripts/**/*.js'], ['scripts']);
}));

gulp.task('default', gulp.parallel('presentations', 'scripts', 'styles', 'articles'));
