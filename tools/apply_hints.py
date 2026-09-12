import json

hints_quimica = {
    27: "Para neutralizar um ácido forte, a alquimia exige o oposto dele na escala de pH. Pense em substâncias que estão acima de 7 na escala.",
    28: "A transição mágica do estado sólido para o líquido com o calor extremo tem um nome clássico na termodinâmica. Lembre-se do que acontece quando o ferro é aquecido na forja.",
    29: "O Sódio (Na) reage violentamente com a água. Na Tabela Periódica, ele lidera o Grupo 1, conhecido por gerar bases fortes. Qual o nome dessa família?",
    30: "Quando o sal dissolve completamente e não conseguimos distinguir a água do sal, formando uma fase única, chamamos de solução. Qual a classificação desse tipo de mistura?",
    31: "Uma reação que libera calor intenso para o ambiente e envolve oxigênio é chamada de exotérmica. No dia a dia, é o processo que faz o fogo queimar.",
    32: "Segundo a teoria antiga de Arrhenius, um ácido é reconhecido pelo que ele libera quando dissolvido em água. Que íons são esses que marcam o caráter ácido?",
    33: "Metais se unem formando uma 'nuvem eletrônica' onde os elétrons fluem livremente. É isso que lhes confere condutividade mágica e térmica. Qual o nome dessa ligação?",
    34: "Quando dois elementos se combinam formando substâncias diferentes (como CO e CO2), eles usam proporções inteiras e fixas. Esta é a lei das Proporções Múltiplas. De quem é a autoria?",
    35: "O Hélio não precisa fazer ligações pois já possui a estabilidade perfeita em sua última camada. Essa família se encontra na última coluna da Tabela Periódica.",
    36: "Quando dois ametais (como H e Cl) precisam de elétrons, eles optam por compartilhar um par. Como a eletronegatividade é diferente, os polos são desiguais. Como chamamos essa ligação?",
    37: "A passagem direta do estado de vapor para o estado sólido (sem virar líquido antes) exige condições extremas. É o reverso da sublimação.",
    38: "Se o ferro perde carga positiva (diminui o Nox), significa que ele recebeu elétrons. O processo de ganho de elétrons na eletroquímica tem um nome específico.",
    39: "No balanceamento mágico: C3H8 + 5 O2 -> 3 CO2 + 4 H2O. Basta observar o coeficiente (número) que acompanha a molécula de oxigênio (O2) para descobrir a resposta.",
    40: "Para separar a areia (sólida) da poção (líquida), usamos uma barreira arcana porosa. O líquido passa, mas os grãos maiores ficam retidos. Qual é o nome dessa técnica?",
    41: "Como a água e o álcool têm pontos de fervura diferentes, o alquimista ferve a mistura. O álcool evapora primeiro e depois é condensado. Qual processo avançado de separação é esse?",
    42: "O Cálcio (Ca) perde 2 elétrons, ficando +2. O Cloro (Cl) ganha 1, ficando -1. Para neutralizar a carga total do sal, você precisará de quantos átomos de cloro para cada cálcio?",
    43: "A ferrugem (oxidação) ocorre quando o metal perde elétrons. Quem causa essa oxidação e sofre a redução ao 'roubar' os elétrons é o gás mais famoso da nossa atmosfera que sustenta o fogo.",
    44: "Catalisadores mágicos servem apenas para acelerar a reação. Eles conseguem isso porque encontram um 'caminho mais fácil' e mágico que exige menos energia inicial (energia de ativação).",
    45: "Íons hidróxido (OH-) determinam a alcalinidade. Se há muito OH- e pouco H+, a poção é muito básica. Na escala de pH (0 a 14), onde se encontram as substâncias básicas?",
    46: "Um carbono central ligado a 4 átomos hidrogênio (sem elétrons sobrando) adota uma forma 3D onde os átomos se distanciam ao máximo. Imagine uma pirâmide de base triangular.",
    47: "O fenômeno de um mesmo elemento formar substâncias simples diferentes (como diamante e grafite, ou O2 e O3) é comum na natureza. O nome disso começa com 'Alo'.",
    48: "Reações que congelam ou absorvem calor do ambiente ao redor, deixando o frasco frio, 'puxam' energia para dentro. Qual o prefixo alquímico para 'dentro' em termoquímica?",
    49: "O Ácido Sulfúrico (H2SO4) possui um número exato de hidrogênios no começo de sua fórmula. Esse número indica a quantidade de prótons que ele pode liberar em solução.",
    50: "Como o fósforo liga-se com ele mesmo (P4), os dois lados têm a mesma força (eletronegatividade) puxando o elétron, não criando polos elétricos. Como se classifica essa ligação?",
    51: "Na reação HCl + NaOH -> NaCl + H2O, a proporção (balanceamento) já é 1:1. Um mol de ácido requer exatamente a mesma quantia de base para ser neutralizado perfeitamente.",
    52: "Se a distribuição eletrônica do Alumínio é 2, 8, 3, a última camada (camada de valência) é aquela que contém os elétrons que participam das ligações químicas. Qual é o último número?",
    79: "A passagem de uma poção do estado líquido, por meio de fervura ou evaporação lenta, para gás mágico, chama-se de modo geral vaporização.",
    80: "A esmeralda e a água não se misturam por completo, e o pó assenta no fundo devido à gravidade. Como chamamos misturas que parecem misturadas mas depois se separam?",
    81: "Elementos químicos puros estão presentes na Tabela Periódica, não podem ser quebrados. Pense em qual destas alternativas simboliza um metal precioso clássico na tabela.",
    82: "Quando há liberação de fumaça, mudança de cor e queima de material gerando cinzas, não é apenas o estado físico que mudou. A estrutura interna das substâncias foi alterada.",
    83: "A escala de pH mede acidez de 0 a 14. O número 7 é o neutro. Quanto mais perto de 0 o valor, mais agressivo e ácido é o composto.",
    84: "Símbolos rúnicos na química geralmente são a primeira letra (ou primeiras letras) do nome do elemento. Oxigênio é essencial para o fogo arcano.",
    85: "As moléculas na superfície da água se unem com tanta força (pontes de hidrogênio) que formam uma fina película elástica invisível. Como chamamos essa resistência na superfície?",
    86: "Substâncias que não se misturam e formam divisões visíveis (como camadas) configuram uma mistura que apresenta múltiplas fases (não uniforme).",
    87: "Na ligação química onde não há doação definitiva, mas sim uma cooperação entre os átomos, os elétrons são compartilhados na nuvem de valência.",
    88: "O núcleo arcano é o centro da matéria. Ele contém duas partículas: os nêutrons (sem carga) e aquelas responsáveis por ditar qual é o elemento e que possuem carga positiva.",
    89: "A famosa Lei da Conservação das Massas, proclamada por Antoine Lavoisier, defende que 'Na natureza nada se cria, nada se perde, tudo se...'",
    90: "Os elétrons mais distantes do núcleo arcano são os únicos que interagem na química. Eles ficam abrigados na camada mais externa da eletrosfera do átomo.",
    91: "A concentração (C = m/v) é o soluto dividido pelo volume. Se você remover (evaporar) metade da água (volume), a poção ficará o dobro mais concentrada!",
    92: "Eles reinam na última coluna da tabela e não interagem com o mundo comum, pois já possuem seus 8 elétrons estabilizados (ou 2, como o Hélio).",
    93: "Água pura, sem impurezas e feitiços, não é ácida nem básica. Ela reside exatamente no meio do equilíbrio cósmico da escala de pH.",
    94: "Alguns átomos (como o flúor e o oxigênio) são egoístas e puxam a nuvem de elétrons da ligação fortemente para si. Como medimos essa força magnética de atração?",
    95: "Reações alquímicas que jogam calor para fora (esquentando o frasco e o ambiente) recebem um prefixo que significa 'liberar' ou 'para fora' térmico.",
    96: "Em oxirredução, os processos ocorrem em pares. Se um agente é 'redutor', ele causa a redução de outro perdendo seus próprios elétrons.",
    97: "Se 1 mol produz 2 mols, estamos falando do dobro. Aplicando a proporção estequiométrica linear: 3 mols gerarão o dobro do seu próprio valor.",
    98: "Alcanos são compostos orgânicos formados puramente de carbono ligado de forma simples a hidrogênios. Pense no gás natural de pântano.",
    99: "Para manter o equilíbrio arcano, a natureza sempre reage de forma contrária à força aplicada nela, buscando anular e neutralizar o efeito externo.",
    100: "A proporção entre os produtos formados e os reagentes restantes no momento em que as reações de ida e volta se igualam é representada por uma letra K (de constante).",
    101: "Pressão e Volume são grandezas inversamente proporcionais. Se você 'aperta' o gás arcano duplicando a força da pressão, o espaço ocupado por ele deve cair na mesma proporção.",
    102: "O Carbono faz duas duplas ligações (como no O=C=O). Como ele se alinha de forma 100% reta (180 graus), seus orbitais mágicos sofrem uma hibridização que usa um s e um p."
}

with open('data/questions.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for q in data:
    if q['id'] in hints_quimica:
        q['dica'] = hints_quimica[q['id']]

with open('data/questions.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
