_.mixin
	shuffle: (arr) ->
		for i in [0...arr.length]
			j = parseInt(Math.random() * i)
			[arr[i], arr[j]] = [arr[j], arr[i]]
		arr

	partition: (arr) ->
		[arr[i], arr[(i+1) % arr.length]] for i in [0...arr.length]

	offset: (arr, offset) -> arr[i % arr.length] for i in [offset...offset+arr.length]

	circRange: (arr, start, stop, step) ->
		[start, stop] = [start, start] if not stop?

		step ?= 1

		stop += arr.length if stop < start and step > 0

		return arr[i % arr.length] for i in [start...stop] by step

	ordering: (obj, iterator, context) ->
		if iterator?
			vals = {i: i, c: iterator.call(obj[i], i, obj)} for i in [0...obj.length]
		else
			vals = {i: i, c: obj[i]} for i in [0...obj.length]

		return v.i for v in vals.sort (left, right) ->
			l = left.c
			r = right.c
			if l < r then -1 else if l > r then 1 else 0

roundTo = (n, k) -> Math.round(n * Math.pow(10, k)) / Math.pow(10, k)

fibonacci = (n) -> if n < 2 then n else fibonacci(n-1) + fibonacci(n-2)
fibonacci = window.fibonacci = _.memoize(fibonacci)

fibonacci.phi = (Math.sqrt(5) + 1) / 2

fibonacci.inverse = (n) -> Math.floor(Math.log((n + 1/2) * Math.sqrt(5)) / Math.log(fibonacci.phi))

class Draw
	WIDTH: 800
	HEIGHT: 600

	canvas: undefined
	VSCALE: undefined
	HSCALE: undefined

	x: (x) -> (x + 1/2) * @HSCALE
	y: (y) -> @HEIGHT - y * @VSCALE

	path: (p) -> @canvas.path(p)
	circle: (x, y, r) -> @canvas.circle(@x(x), @y(y), r)

	hLine: (x1, x2, y) -> "M#{@x(x1)} #{@y(y)}H#{@x(x2)}"
	vLine: (y1, y2, x) -> "M#{@x(x)} #{@y(y1)}V#{@y(y2)}"

class Message extends Draw
	constructor: (@n1, @n2, @id) ->
		@id ?= @n1.id

		@color = if @n1.stage % 2 == 0 then '#182' else '#125'

		@t = @canvas.path().attr({stroke: '#aaa', 'stroke-dasharray': '- '})
		@m = @circle(@n1.index, @id, 5).attr({'stroke-width': 1.5, stroke: @color, scale: 2.5, fill: '#fff', 'fill-opacity': 0.05, opacity: 0})

		@to(@n2)

	num: ->
		(@NODES + @n2.index - @n1.index - 1) % @NODES + 1

	clone: ->
		obj = ->
		obj.prototype = this
		result = new obj
		result.t = @t.clone()
		result.m = @m.clone()
		return result

	to: (n) ->
		num = (@NODES + n.index - @n2.index - 1) % @NODES + 1

		@n2 = n

		if @n2.index < @n1.index
			@t.attr('path', @hLine(@n1.index, @NODES - 1/2, @id) + @hLine(-1/2, @n2.index, @id))
		else
			@t.attr('path', @hLine(@n1.index, @n2.index, @id))

		@m.attr({'stroke-width': 1.5, stroke: @color, scale: 2.5, fill: '#fff', 'fill-opacity': 0.05, opacity: 0})

		@m.animate({scale: 1, opacity: 1}, 300, =>
			if @x(@n2.index) < @m.attr('cx')
				@m.animate({
					'50%': {cx: @x(@NODES-1/2), easing: '<', callback: () =>
						@m.attr({cx: @x(-1/2)})
					},
					'100%': {cx: @x(@n2.index), easing: '>'}
				}, 1000)
			else
				@m.animate({cx: @x(@n2.index)}, 1000, '<>')
		)

		num

	hide: ->
		@m.animate({scale: 2.5, opacity: 0}, 2000, () => @m.remove())
		@t.animate({opacity: 0}, 2000, () => @t.remove())

class Node extends Draw
	constructor: (@id, @index) ->
		@state = 'default'
		@stage = 1

		@l = @path(@vLine(0, @id, @index))
		@c = @circle(@index, @id, 3)
		@s = @canvas.set([@l, @c]).attr({stroke: '#125', fill: '#125', 'stroke-width': 1.2})

	clone: (id, stage, state) ->
		obj = ->
		obj.prototype = this
		return new obj

	defeat: (state) ->
		@state = (state ?= 'defeated')

		if @state == 'defeated'
			@l.attr('stroke-dasharray', '')
			@s.animate({
				'30%': {stroke: '#f00', fill: '#f00', 'stroke-width': 4},
				'100%': {stroke: '#ccc', fill: '#ccc', 'stroke-width': 1}
			}, 1000)
		else if @state == 'temp'
			@l.attr('stroke-dasharray', '- ')
			@s.animate({
				'100%': {stroke: '#8b2', fill: '#8b2'}
			}, 1000)

	revive: (@id, @stage) ->
		@state = 'default'
		color = if @stage % 2 == 0 then '#182' else '#125'
		@l.attr('stroke-dasharray', '')
		@s.animate({
			'30%': {stroke: '#f00', fill: '#f00', 'stroke-width': 4},
			'100%': {stroke: color, fill: color, 'stroke-width': 1}
		}, 1000)
		@c.animate({cy: @y(@id)}, 1000, '<>')
		@l.animate({path: @vLine(0, @id, @index)}, 1000, '<>')

	update: (@id, @stage) ->
		color = if @stage % 2 == 0 then '#182' else '#125'
		@s.animate({stroke: color, fill: color})
		@c.animate({cy: @y(@id)}, 1000, '<>')
		@l.animate({path: @vLine(0, @id, @index)}, 1000, '<>')

class Ring extends Draw
	constructor: ->
		Draw::canvas = Raphael('canvas', @WIDTH, @HEIGHT)

		$('select[name=values]').change => @updateShowSeed()

		$('select[name=proto]').change => @refresh()

		$('form#options').submit =>
			@refresh()
			false

		$(@canvas.canvas).click () => @move()

		@refresh()
		@updateShowSeed()

	updateShowSeed: ->
		if $('select[name=values] option:selected').val() == 'random'
			$('span.random').css('display', 'inline')
		else
			$('span.random').css('display', 'none')

	worstCase: (n, stage) ->
		return [1] if n == 1
		return [1, 2] if n == 2
		stage ?= 1
		i = 0
		nfib = fibonacci(fibonacci.inverse(n) - 1)
		nfib2 = fibonacci(fibonacci.inverse(n) - 2)
		if fibonacci(fibonacci.inverse(n)) == n
			vals = @worstCase(nfib, 1 - stage)
			result = []
			for [x, y] in _(vals).partition()
				result.push(x)
				if stage and x > y
					result.push(10000 - (i++))
				else if not stage and x < y
					result.push(- (i++))
			return 1 + i for i in _.ordering(_.ordering(result))
		j = 0
		k = (n - nfib) % nfib2
		q = Math.floor((n - nfib) / nfib2)
		i = nfib + 1
		vals = @worstCase(nfib, 1 - stage)
		result = []
		for [x, y] in _(vals).partition()
			result.push(x)
			if stage and x > y
				for b in [1..(if j < k then q + 1 else q)]
					result.push(10000 - (i++))
				j++
			else if not stage and x < y
				for b in [1..(if j < k then q + 1 else q)]
					result.push(- (i++))
				j++
		return 1 + i for i in _.ordering(_.ordering(result))

	refresh: ->
		Draw::NODES = parseInt($('input[name=nodes]').val())
		Draw::VSCALE = @HEIGHT / (@NODES+2)
		Draw::HSCALE = @WIDTH / (@NODES)

		@canvas.clear()

		@nodes = window.nodes = []

		$('#messages').empty()

		switch $('select[name=proto] option:selected').val()
			when 'minmax' then @proto = @minMax
			when 'asfar' then @proto = @asFar
			when 'unistages' then @proto = @uniStages
			when 'unialternate' then @proto = @uniAlternate
			else @proto = @minMaxPlus

		if $('select[name=values] option:selected').val() == 'random'
			val = $('input[name=seed]').val()
			val or= parseInt(10000 * Math.random())
			@log("Using seed: #{val}")
			Math.seedrandom(val)
			pos = _([1..@NODES]).shuffle()
			Math.seedrandom()
		else if @proto is @asFar
			pos = [1..@NODES]
		else
			pos = @worstCase(@NODES)

		for i in [0...@NODES]
			@nodes.push(new Node(pos[i], i))

		@state = 0
		@stage = 1
		@nmsg = 0
		@l = @canvas.text(400, @VSCALE, '').attr({'font-size': 14})
		@msgs = {}

	log: (text) ->
		$('<li/>').html(text).appendTo('#messages')

	cloneNodes: -> n.clone() for n in @nodes

	sendMessage: (n1, n2, msg) ->
		if msg?
			delete @msgs[[msg.n1.index, msg.n2.index]]
			num = (@NODES + n2.index - msg.n2.index - 1) % @NODES + 1
			msg.to(n2)
		else
			num = (@NODES + n2.index - n1.index - 1) % @NODES + 1
			msg = new Message(n1, n2)

		@msgs[[n1.index, n2.index]] = msg

		num

	hideMessage: (n1, n2) ->
		@msgs[[n1.index, n2.index]].hide()
		delete @msgs[[n1.index, n2.index]]

	candidates: -> (n for n in @nodes when n.state == 'default')

	forCandidates: (fn) -> fn(n1, n2) for [n1, n2] in _(@candidates()).partition()

	done: ->
		@state = -1
		@log("===== Finished =====")
		@log("Total: <strong>#{@nmsg} = #{roundTo(@nmsg / @NODES, 3)} * n = #{roundTo(@nmsg / (@NODES * Math.log(@NODES)/Math.log(2)), 3)} * n log n messages</strong>")

	showStage: (name) -> "Stage #{@stage} (#{name}) - <strong>#{@candidates().length}</strong> candidates"

	asFar: [
		->
			@forCandidates (n1, n2) =>
				@nmsg += @sendMessage(n1, n2)
				n1.msg = @msgs[[n1.index, n2.index]]
		->
			@state = 1

			for n1 in @nodes when n1.msg
				n2 = n1.msg.n2
				if n1.id > n2.id
					@hideMessage(n1, n2)
					delete n1.msg
				else if n1.id < n2.id
					n2.defeat()

			for n1 in @nodes when n1.msg
				for n2 in _(@nodes).offset(n1.msg.n2.index + 1) when n2.state == 'default'
					@nmsg += @sendMessage(n1, n2, n1.msg)
					if n1.index == n2.index
						@state = 2
					break
		->
			for n1 in @nodes when n1.msg
				@hideMessage(n1, n1.msg.n2)
				delete n1.msg
			@done()
	]

	uniStages: [
		->
			@forCandidates (n1, n2) =>
				n2.msg1 = new Message(n1, n2)
				n2.nbr1 = n1
				@nmsg += n2.msg1.num()
				if n1.index == n2.index
					@state = 4
		->
			@forCandidates (n1, n2) =>
				n2.msg2 = n1.msg1.clone()
				n2.nbr2 = n1.nbr1
				@nmsg += n2.msg2.to(n2)
				if n1.index == n2.index
					@state = 4
		->
			for n in @candidates()
				if n.nbr1.id >= n.id or n.nbr1.id >= n.nbr2.id
					n.defeat()
					n.msg1.hide()
					n.msg2.hide()
		->
			@state = 0
			@newNodes = @cloneNodes()
			for n in @candidates()
				if n.nbr1.id < n.id and n.nbr1.id < n.nbr2.id
					@newNodes[n.index].update(n.nbr1.id)
					n.msg1.hide()
					n.msg2.hide()
			@nodes = @newNodes
		->
			@done()
	]

	uniAlternate: [
		->
			@forCandidates (n1, n2) => @nmsg += @sendMessage(n1, n2)
		->
			@forCandidates (n1, n2) =>
				if n1.id < n2.id
					n2.defeat()
				else if n1.id == n2.id
					@state = 4
				@hideMessage(n1, n2)
		->
			@forCandidates (n1, n2) => @nmsg += @sendMessage(n1, n2)
		->
			@state = 0
			@newNodes = @cloneNodes()
			@forCandidates (n1, n2) =>
				if n1.id > n2.id
					@newNodes[n2.index].defeat()
				else if n1.id < n2.id
					@newNodes[n2.index].update(n1.id)
				else if n1.id == n2.id
					@state = 4
				@hideMessage(n1, n2)
			@nodes = @newNodes
		->
			@done()
	]

	minMax: [
		->
			@log(@showStage('MIN'))
			@newNodes = @cloneNodes()
			@forCandidates (n1, n2) => @nmsg += @sendMessage(n1, n2)
		->
			num = 0
			@forCandidates (n1, n2) =>
				if n2.id < n1.id
					@newNodes[n2.index].defeat()
					@hideMessage(n1, n2)
					num += 1
			@log("#{num} nodes defeated")
		->
			@forCandidates (n1, n2) =>
				if n2.id > n1.id
					@newNodes[n2.index].update(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
				else if n2.id == n1.id
					@done()
			@stage++
			@nodes = @newNodes
		->
			@log(@showStage('MAX'))
			@newNodes = @cloneNodes()
			@forCandidates (n1, n2) => @nmsg += @sendMessage(n1, n2)
		->
			num = 0
			@forCandidates (n1, n2) =>
				if n2.id > n1.id
					@newNodes[n2.index].defeat()
					@hideMessage(n1, n2)
					num += 1
			@log("#{num} nodes defeated")
		->
			@forCandidates (n1, n2) =>
				if n2.id < n1.id
					@newNodes[n2.index].update(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
				else if n2.id == n1.id
					@done()
			@stage++
			@nodes = @newNodes
	]

	forMinCandidates: (fn) ->
		for n1 in @candidates() when n1.stage % 2 == 1
			for n2 in _(@nodes).offset(n1.index + 1) when n2.state != 'defeated'
				if n2.stage % 2 == 1 or n2.state == 'temp' and n2.id > n1.id
					fn(n1, n2)
					break

	forMaxCandidates: (fn) ->
		for n1 in @candidates() when n1.stage % 2 == 0
			for n2 in _(@nodes).offset(n1.index + 1)
				if (@NODES + n2.index - n1.index) % @NODES >= fibonacci(n1.stage + 1) or n2.state == 'default' and n2.stage % 2 == 0
					fn(n1, n2)
					break

	minMaxPlus: [
		->
			@forMinCandidates (n1, n2) =>
				for n in _(@nodes).circRange(n1.index + 1, n2.index) when n.state != 'defeated'
					n.defeat()
				@nmsg += @sendMessage(n1, n2)
			@log(@showStage('MIN'))
		->
			@newNodes = @cloneNodes()
			num = 0
			@forMinCandidates (n1, n2) =>
				if n2.id < n1.id
					@newNodes[n2.index].defeat()
					@hideMessage(n1, n2)
					num += 1
			@log("#{num} nodes defeated")
		->
			num = 0
			@forMinCandidates (n1, n2) =>
				if n2.state == 'temp'
					@newNodes[n2.index].revive(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
					num += 1
				else if n2.id > n1.id
					@newNodes[n2.index].update(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
				else if n2.id == n1.id
					@done()
			@log("#{num} defeated nodes promoted early to candidates") if num > 0
			@nodes = @newNodes
		->
			@forMaxCandidates (n1, n2) =>
				for n in _(@nodes).circRange(n1.index + 1, n2.index) when n.state != 'defeated'
					n.defeat()
				@nmsg += @sendMessage(n1, n2)
			@log(@showStage('MAX'))
		->
			@newNodes = @cloneNodes()
			num = 0
			@forMaxCandidates (n1, n2) =>
				if n2.state == 'default' and n2.id > n1.id
					@newNodes[n2.index].defeat('temp')
					@hideMessage(n1, n2)
					num += 1
				else if n2.state == 'default' and n2.id == n1.id
					@done()
			@log("#{num} nodes defeated")
		->
			num = 0
			@forMaxCandidates (n1, n2) =>
				if n2.state == 'defeated'
					@newNodes[n2.index].revive(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
					num += 1
				else if n2.id < n1.id
					@newNodes[n2.index].update(n1.id, n1.stage + 1)
					@hideMessage(n1, n2)
				else if n2.id == n1.id
					@done()
			@log("#{num} defeated nodes became candidates again")
			@nodes = @newNodes
	]

	move: ->
		return if @state < 0
		nmsg = @nmsg
		@state = ((state = @state) + 1) % @proto.length
		@proto[state].call(this)
		@log("Messages sent: #{@nmsg} = #{roundTo(@nmsg / @NODES, 3)} * n") if @nmsg != nmsg

$ -> window.ring = new Ring()