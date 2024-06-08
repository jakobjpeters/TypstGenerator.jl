struct TypstContext
	brackets::Bool
	indent::Int
end

create_context(brackets::Bool, indent::Int = 0) = TypstContext(brackets, indent)

render(t::TypstSpacing, context::TypstContext) = "$(render(context,t))($(getproperty(t, :spacing)))"

render(t::Pair{Symbol, Any}) = "$(replace(string(t[1]), "_" => "-")): $((t[2] |> typeof <: TypstElement) ? render(t[2], create_context(false)) : render(t[2]))"

render(t::Pair{Symbol, TypstElement}) = "$(t[1]): $(t[2] |> render)"

render(t::Pair{Symbol, TypstVec}) = "$(t[1]): $(t[2] |> render)"

render(t::Pair{Symbol, Union{AbstractString, Symbol}}) = """$(replace(string(t[1]), "_" => "-")): $(t[2] |> render)"""

render(e::Symbol, context::TypstContext) = """\"$(e)\""""

render(e::Symbol) = "$(e)"

render(e::NamedTuple) = "($(join(map(x -> "$(render(x[1])): $(render(x[2]))", e |> pairs |> collect), ", ")))"

render(e::TypstNumbering, context::TypstContext) = """$(render(context,e))($(join(map(x -> typeof(x) <: AbstractString ? "\"$(x)\"" : "$(x)",  e.numbering), ", ")))"""

render(c::TypstContext, e) = "$(render(c))$(name(e))"

render(e::TypstMath, _) = "\$$(e.expr)\$"

render(t::TypstLink, context::TypstContext) = "$(render(context,t))(\"$(t.dest)\", $(render(t.content,create_context(false, context.indent))))"

render(e::TypstVec, context::TypstContext) = "\n" * join(map(x -> render(x, context), e), context.brackets ? "\n" : ",\n")

render(t::TypstAlign, context::TypstContext) = "$(render(context,t))($(t.align), $(render(t.content,create_context(false, context.indent))))"

render(t::TypstColumns, context::TypstContext) = "$(render(context,t))($(t.num)$(render(t.options,prefixif = ", ")))[$(render(t.content,create_context(true, context.indent + 1)))]"

render(e::BaseOptions; prefixif = "", suffixif = "") = isempty(e) ? "" : "$(prefixif)$(join(e |> collect .|> render, ", "))$(suffixif)"

render(e::TypstCite, context::TypstContext) = "$(render(context,e))($(join(map(ref -> "\"$(ref)\"", e.refs), ", "))$(render(e.options, prefixif = ", ")))"

render(e::TypstPlace, context::TypstContext) = "$(render(context,e))($(e.alignment),$(render(e.options, suffixif = ", "))$(render(e.content, create_context(false, context.indent + 1))))"

render(e::TypstRotate, context::TypstContext) = "$(render(context,e))($(render(e.angle)),$(render(e.options, suffixif = ", "))$(render(e.content, create_context(false, context.indent + 1))))"

render(e::TypstSet, context::TypstContext) = "$(context |> render)set $(e.type |> name)($(render(e.options)))"

render(e::TypstSingle, context::TypstContext) = "$(render(context,e))($(getproperty(e, fieldnames(typeof(e))[1])))"

render(e::TypstReference, context::TypstContext) = "$(render(context,e))($(render(e.options))<$(e.label)>)"

render(e::Type, ref::Option{Symbol}) = e <: TypstReferable && !isnothing(ref) ? "<$(ref)>" : ""

function render(e::Union{TypstBaseElement, TypstBaseControlls}, context::TypstContext)::String
	newcontext = create_context(e.type <: TypstBracket, context.indent + 1)
	render(context, e.type) * (newcontext.brackets ?
							   "($(render(e.options)))[$(render(e.content, newcontext))]" :
							   "($(render(e.options, suffixif = ", "))$(typeof(e) == TypstBaseElement ? render(e.content, newcontext) : "")) ") * render(e.type, e.ref)
end

render(x::Union{
	AbsoluteLength,
	AbstractString,
	Bool,
	Flex,
	Fractional,
	Int,
	RelativeLength,
	TypstAngle,
	TypstCMYK,
	TypstContext,
	TypstLiteral,
	TypstLuma,
	TypstRGB
}) = sprint((io, x) -> show(io, MIME"text/typst"(), x), Typst(x))

render(x::AbstractString, context::TypstContext) =
	sprint((io, x) -> show(io, MIME"text/typst"(), Typst(x)), x;
		context = (:brackets => context.brackets, :depth => context.indent, :indent => "  "))

render(x::TypstContext) =
	sprint((io, x) -> show(io, MIME"text/typst"(), Typst(x)), x;
		context = (:brackets => x.brackets, :depth => x.indent, :indent => "  "))

show_typst(io, t::AbsoluteLength) = print(io, t.value, "mm")

show_typst(io, t::Flex) = if !isempty(t) join(io, render.(t), ", ") end

show_typst(io, t::Fractional) = print(io, t.val, "fr")

show_typst(io, t::RelativeLength) = print(io, t.value * 100 |> round |> Int)

show_typst(io, i::TypstAngle) = print(io, i.value, "deg")

function show_typst(io, i::TypstCMYK)
	print(io, "cmyk(")
	join(io, map(render ∘ RelativeLength, [i.cyan, i.magenta, i.yellow, i.key]), ", ")
	print(io, ")")
end

show_typst(io, t::TypstContext) =
	print(io, io[:indent]::String ^ io[:depth]::Int, io[:brackets]::Bool ? "#" : "")

show_typst(io, e::TypstLiteral) = print(io, e.string)

show_typst(io, i::TypstLuma) = print(io, "luma(", i.value, ")")

function show_typst(io, i::TypstRGB)
	print(io, "rbg(")
	join(io, [i.r, i.g, i.b], ", ")
	print(io, ")")
end
