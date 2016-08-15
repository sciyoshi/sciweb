"use strict";

let gulp = require('gulp');
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

let template = (name) => {
	let pug = require('pug');

	return through.obj(function(file, enc, cb) {
		let data = {
			contents: file.contents,
			page: file.page
		};
		file.contents = new Buffer(pug.renderFile(`templates/${name}.pug`, data), 'utf8');
		this.push(file);
		cb();
	});
}

gulp.task('articles-md', () =>
	gulp.src(['content/articles/*.md'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}))
		.pipe(markdown())
		.pipe(template('base'))
		.pipe(gulp.dest('build/content/articles/'))
);

gulp.task('articles-html', () =>
	gulp.src(['content/articles/*.html'])
		.pipe(frontmatter({
			property: 'page',
			remove: true
		}))
		.pipe(template('base'))
		.pipe(gulp.dest('build/content/articles/'))
);

gulp.task('articles', gulp.parallel('articles-md', 'articles-html'));

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
