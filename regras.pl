% =====================================================================
% REGRAS - Knowledge Engine Copas do Mundo
% =====================================================================
% Este arquivo contem as regras (sentencas) que serao anexadas aos fatos
% copa/10 pelo etl.py para formar o arquivo final copas.pl.
%
% Convencoes:
%   - Predicados auxiliares (helpers) ficam na primeira secao.
%   - Cada uma das 3 perguntas tem uma secao propria, em ordem crescente
%     de complexidade.
% =====================================================================


% =====================================================================
% PREDICADOS AUXILIARES
% =====================================================================

% pais/1 - enumera todo pais que aparece em qualquer posicao da base.
% Usado para "amarrar" o argumento de findall e evitar variaveis livres
% (erro comum apontado no PDF do projeto).
pais(P) :- copa(_, P, _, _, _, _, _, _, _, _).
pais(P) :- copa(_, _, P, _, _, _, _, _, _, _).
pais(P) :- copa(_, _, _, P, _, _, _, _, _, _).
pais(P) :- copa(_, _, _, _, P, _, _, _, _, _).
pais(P) :- copa(_, _, _, _, _, P, _, _, _, _).

% campeao/2 - relaciona o pais campeao ao ano da edicao.
campeao(Pais, Ano) :- copa(Ano, _, Pais, _, _, _, _, _, _, _).

% sediou/2 - pais que sediou a copa em determinado ano.
sediou(Pais, Ano) :- copa(Ano, Pais, _, _, _, _, _, _, _, _).


% =====================================================================
% PERGUNTA 1 (sofisticada): Ranking de paises por numero de titulos
% mundiais conquistados.
% ---------------------------------------------------------------------
% Tecnicas usadas:
%   - composicao de regras (titulos/2 chama campeao/2 e pais/1)
%   - agregacao com findall + length (conta titulos por pais)
%   - ordenacao decrescente com setof + reverse
% =====================================================================

% titulos(Pais, N) - N e o numero de vezes que Pais foi campeao.
% So sucede quando N > 0 (paises que nunca ganharam ficam de fora).
titulos(Pais, N) :-
    pais(Pais),
    findall(Ano, campeao(Pais, Ano), Lista),
    length(Lista, N),
    N > 0.

% ranking_titulos(Ranking) - lista [N-Pais, ...] em ordem decrescente.
% setof remove duplicatas e ordena crescente; reverse inverte para
% mostrar o maior campeao primeiro.
ranking_titulos(Ranking) :-
    setof(N-Pais, titulos(Pais, N), Crescente),
    reverse(Crescente, Ranking).


% =====================================================================
% PERGUNTA 2 (sofisticada): Top 5 edicoes com maior media de gols por
% partida.
% ---------------------------------------------------------------------
% Tecnicas usadas:
%   - aritmetica (divisao gols / partidas)
%   - ordenacao com setof + reverse
%   - composicao com append para "fatiar" o topo da lista
% =====================================================================

% media_gols(Ano, Media) - media de gols por partida na edicao Ano.
media_gols(Ano, Media) :-
    copa(Ano, _, _, _, _, _, Gols, _, Partidas, _),
    Media is Gols / Partidas.

% ranking_media_gols(Ranking) - lista [Media-Ano, ...] decrescente.
ranking_media_gols(Ranking) :-
    setof(M-Ano, media_gols(Ano, M), Crescente),
    reverse(Crescente, Ranking).

% top5_media_gols(Top5) - pega apenas os 5 primeiros do ranking.
top5_media_gols(Top5) :-
    ranking_media_gols(Todos),
    length(Top5, 5),
    append(Top5, _, Todos).


% =====================================================================
% PERGUNTA 3 (sofisticada): Quais paises foram campeoes jogando a Copa
% em casa, e quantas vezes cada um?
% ---------------------------------------------------------------------
% Tecnicas usadas:
%   - unificacao dupla (mesma variavel Pais em duas posicoes do fato,
%     o Prolog filtra automaticamente as edicoes onde Sede == Campeao)
%   - agregacao por pais com findall + length
%   - ordenacao com setof + reverse
% =====================================================================

% campeao_em_casa(Pais, Ano) - Pais sediou e venceu a copa de Ano.
campeao_em_casa(Pais, Ano) :-
    copa(Ano, Pais, Pais, _, _, _, _, _, _, _).

% vezes_campeao_em_casa(Pais, N) - N edicoes em que Pais foi campeao
% jogando em casa (so sucede para N > 0).
vezes_campeao_em_casa(Pais, N) :-
    pais(Pais),
    findall(Ano, campeao_em_casa(Pais, Ano), Lista),
    length(Lista, N),
    N > 0.

% ranking_campeao_em_casa(Ranking) - lista [N-Pais, ...] decrescente.
ranking_campeao_em_casa(Ranking) :-
    setof(N-Pais, vezes_campeao_em_casa(Pais, N), Crescente),
    reverse(Crescente, Ranking).


% =====================================================================
% QUERIES DE EXEMPLO (copie para a celula Query do SWISH)
% ---------------------------------------------------------------------
% ?- ranking_titulos(R).
% ?- top5_media_gols(T).
% ?- ranking_campeao_em_casa(R).
% =====================================================================
