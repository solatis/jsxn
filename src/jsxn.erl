%% The MIT License

%% Copyright (c) 2010-2013 alisdair sullivan <alisdairsullivan@yahoo.ca>

%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:

%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.

%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.


-module(jsxn).

-export([encode/1, encode/2, decode/1, decode/2]).
-export([is_json/1, is_json/2, is_term/1, is_term/2]).
-export([format/1, format/2, minify/1, prettify/1]).
-export([encoder/3, decoder/3, parser/3]).
-export([resume/3]).

-export_type([json_term/0, json_text/0, token/0]).
-export_type([encoder/0, decoder/0, parser/0, internal_state/0]).
-export_type([config/0]).


-type json_term() :: [{binary() | atom(), json_term()}] | [{}]
    | [json_term()] | []
    | #{}
    | true | false | null
    | integer() | float()
    | binary() | atom().

-type json_text() :: binary().

-type config() :: jsx_config:config().

-spec encode(Source::json_term()) -> json_text() | {incomplete, encoder()}.
-spec encode(Source::json_term(), Config::jsx_to_json:config()) -> json_text() | {incomplete, encoder()}.

encode(Source) -> jsx:encode(Source, []).
encode(Source, Config) -> jsx:encode(Source, Config).


-spec decode(Source::json_text()) -> json_term() | {incomplete, decoder()}.
-spec decode(Source::json_text(), Config::jsx_to_term:config()) -> json_term()  | {incomplete, decoder()}.

decode(Source) -> decode(Source, []).
decode(Source, Config) -> jsx:decode(Source, Config ++ [return_maps]).


-spec format(Source::json_text()) -> json_text() | {incomplete, decoder()}.
-spec format(Source::json_text(), Config::jsx_to_json:config()) -> json_text() | {incomplete, decoder()}.

format(Source) -> jsx:format(Source, []).
format(Source, Config) -> jsx:format(Source, Config).


-spec minify(Source::json_text()) -> json_text()  | {incomplete, decoder()}.

minify(Source) -> jsx:format(Source, []).


-spec prettify(Source::json_text()) -> json_text() | {incomplete, decoder()}.

prettify(Source) -> jsx:format(Source, [space, {indent, 2}]).


-spec is_json(Source::any()) -> true | false.
-spec is_json(Source::any(), Config::jsx_verify:config()) -> true | false.

is_json(Source) -> jsx:is_json(Source, []).
is_json(Source, Config) -> jsx:is_json(Source, Config).


-spec is_term(Source::any()) -> true | false.
-spec is_term(Source::any(), Config::jsx_verify:config()) -> true | false.

is_term(Source) -> jsx:is_term(Source, []).
is_term(Source, Config) -> jsx:is_term(Source, Config).


-type decoder() :: fun((json_text() | end_stream) -> any()).

-spec decoder(Handler::module(), State::any(), Config::list()) -> decoder().

decoder(Handler, State, Config) -> jsx:decoder(Handler, State, Config).


-type encoder() :: fun((json_term() | end_stream) -> any()).

-spec encoder(Handler::module(), State::any(), Config::list()) -> encoder().

encoder(Handler, State, Config) -> jsx:encoder(Handler, State, Config).


-type token() :: [token()]
    | start_object
    | end_object
    | start_array
    | end_array
    | {key, binary()}
    | {string, binary()}
    | binary()
    | {number, integer() | float()}
    | {integer, integer()}
    | {float, float()}
    | integer()
    | float()
    | {literal, true}
    | {literal, false}
    | {literal, null}
    | true
    | false
    | null
    | end_json.


-type parser() :: fun((token() | end_stream) -> any()).

-spec parser(Handler::module(), State::any(), Config::list()) -> parser().

parser(Handler, State, Config) -> jsx:parser(Handler, State, Config).

-opaque internal_state() :: tuple().

-spec resume(Term::json_text() | token(), InternalState::internal_state(), Config::list()) -> any().

resume(Term, {decoder, State, Handler, Acc, Stack}, Config) ->
    jsx_decoder:resume(Term, State, Handler, Acc, Stack, jsx_config:parse_config(Config));
resume(Term, {parser, State, Handler, Stack}, Config) ->
    jsx_parser:resume(Term, State, Handler, Stack, jsx_config:parse_config(Config)).



-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

basic_decode_test_() ->
    [
        {"empty object", ?_assertEqual(#{}, decode(<<"{}">>))},
        {"simple object", ?_assertEqual(
            #{<<"key">> => <<"value">>},
            decode(<<"{\"key\": \"value\"}">>)
        )},
        {"nested object", ?_assertEqual(
            #{<<"key">> => #{<<"key">> => <<"value">>}},
            decode(<<"{\"key\": {\"key\": \"value\"}}">>)
        )},
        {"complex object", ?_assertEqual(
            #{<<"key">> => [
                    #{<<"key">> => <<"value">>},
                    #{<<"key">> => []},
                    #{<<"key">> => 1.0},
                    true,
                    false,
                    null
                ],
                <<"another key">> => #{}
            },
            decode(<<"{\"key\": [
                    {\"key\": \"value\"},
                    {\"key\": []},
                    {\"key\": 1.0},
                    true,
                    false,
                    null
                ], \"another key\": {}
            }">>)
        )},
        {"empty list", ?_assertEqual([], decode(<<"[]">>))},
        {"raw value", ?_assertEqual(1.0, decode(<<"1.0">>))}
    ].

-endif.