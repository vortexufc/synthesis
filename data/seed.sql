-- Seed file for the "perguntas" table
-- Total of 78 thematic questions (26 Biology, 26 Chemistry, 26 Physics)
-- Floor IDs: 1 = Química, 2 = Física, 3 = Biologia

DROP TABLE IF EXISTS perguntas CASCADE;

CREATE TABLE perguntas (
    id SERIAL PRIMARY KEY,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    answer SMALLINT NOT NULL,
    andar_id INTEGER NOT NULL,
    nivel_progresso INTEGER DEFAULT 1
);


-- ==========================================
-- ANDAR 3 - BIOLOGIA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('Um jovem mago percebeu que, ao conjurar um feitiço de cura, a energia regenerativa estimula a divisão de células somáticas da pele ferida do guerreiro. Que processo celular de divisão de células idênticas o feitiço acelerou?', 
 '["Mitose", "Meiose", "Fissão binária", "Esporulação"]', 0, 3, 1),

('O Slime Verde da masmorra absorve nutrientes digerindo matéria orgânica externamente antes de a absorver. De acordo com a biologia, que tipo de nutrição esse ser compartilha com os fungos terrestres?', 
 '["Autotrófica por fotossíntese", "Heterotrófica por absorção", "Quimiolitoautotrófica", "Autotrófica por quimiossíntese"]', 1, 3, 1),

('Nas estufas arcanas da torre, as plantas de mana purificam o ar utilizando a luz solar para sintetizar glicose a partir de dióxido de carbono gasoso e água. Que organela celular é responsável por essa conversão mágica?', 
 '["Mitocôndria", "Complexo de Golgi", "Cloroplasto", "Lisossomo"]', 2, 3, 1),

('Uma poção vigorizante atua fornecendo alta carga de energia celular direta na forma de ATP (Adenosina Trifosfato). Em qual organela celular a maior parte do ATP é sintetizada por meio da respiração celular?', 
 '["Ribossomo", "Lisossomo", "Retículo endoplasmático", "Mitocôndria"]', 3, 3, 2),

('Um alquimista estuda o veneno de uma aranha da masmorra e descobre que ele bloqueia a síntese de proteínas nas células da vítima. Qual organela celular responsável pela tradução do RNAm foi paralisada pelo veneno?', 
 '["Ribossomo", "Nucléolo", "Peroxissomo", "Centríolo"]', 0, 3, 2),

('Para criar um clone estável de um homúnculo, o mago precisa extrair a molécula dupla-hélice que carrega a informação genética completa da criatura. Qual é o nome dessa molécula biológica?', 
 '["RNA mensageiro", "Ácido Desoxirribonucleico (DNA)", "Trifosfato de adenosina (ATP)", "Polipeptídeo cristalino"]', 1, 3, 1),

('Os slimes gigantes da torre se reproduzem dividindo-se ao meio em dois slimes idênticos menores, sem troca de material genético. Esse método de reprodução assexuada é análogo a qual processo de reprodução de bactérias?', 
 '["Conjugação bacteriana", "Brotamento mitótico", "Divisão binária (ou cissiparidade)", "Partenogênese induzida"]', 2, 3, 2),

('Em uma simulação de ecossistema na torre, o mago observa que os robôs coletores (consumidores secundários) acumulam toxinas de metais mágicos em maior concentração que os slimes coletores (consumidores primários). Esse fenômeno ecológico é chamado de:', 
 '["Nicho ecológico", "Sucessão ecológica", "Eutrofização controlada", "Magnificação trófica (ou bioacumulação)"]', 3, 3, 3),

('As células do Mago Negro possuem uma parede celular rígida externa que protege contra flutuações de pressão osmótica na água circundante. De acordo com a biologia celular vegetal, qual substância carboidrato compõe essa estrutura de proteção?', 
 '["Celulose", "Glicogênio", "Quitina", "Amido"]', 0, 3, 2),

('O dragão de fogo da torre consome grandes quantidades de lipídios da masmorra para armazenar energia de longo prazo sob a forma de gordura térmica sob suas escamas. Qual das seguintes funções melhor descreve os lipídios na biologia?', 
 '["Catalisadores enzimáticos exclusivos", "Reserva de energia e isolamento térmico", "Transportadores rápidos de oxigênio no sangue", "Estrutura básica do material genético principal"]', 1, 3, 1),

('Ao conjurar um feitiço de envelhecimento rápido sobre um troll, o mago altera a expressão do material genético sem modificar a sequência de bases nitrogenadas do DNA do troll. Esse ramo de estudo da genética é conhecido como:', 
 '["Epigenética", "Mutagênese direcionada", "Clonagem molecular", "Transgênese cromossômica"]', 0, 3, 3),

('Uma poção de rejuvenescimento celular contém uma enzima que repara as extremidades repetitivas dos cromossomos, que encurtam a cada divisão celular rúnica. Qual o nome biológico dessas extremidades protetoras do DNA?', 
 '["Cinetócoros", "Telômeros", "Centrômeros", "Histonas"]', 1, 3, 3),

('Um caçador arcano analisa o sangue azul de um caranguejo da masmorra e nota que ele transporta oxigênio usando cobre em vez de ferro. Que proteína respiratória de cor azulada realiza essa função na biologia?', 
 '["Hemoglobina", "Mioglobina", "Hemocianina", "Clorofila"]', 2, 3, 3),

('O mago observa que, após um incêndio florestal provocado por uma bola de fogo, liquens arcanos e briófitas (musgos) são os primeiros a colonizar as rochas expostas na masmorra. Qual o termo ecológico para essa primeira comunidade colonizadora?', 
 '["Comunidade pioneira (ou ecese)", "Comunidade clímax", "Comunidade de transição (sere)", "Comunidade degradada"]', 0, 3, 2),

('Uma poção concentrada ativa um morcego da masmorra a usar ecolocalização para caçar no escuro, emitindo ondas sonoras que colidem em obstáculos e retornam. Qual o nome biológico desse sentido sensorial adaptativo?', 
 '["Magnetorecepção", "Ecolocalização (ou biossonar)", "Quimiorecepção", "Eletrorecepção"]', 1, 3, 1),

('O veneno de uma serpente arcana dissolve a bainha de mielina dos neurônios do jogador, diminuindo drasticamente a velocidade de propagação dos impulsos nervosos. Qual a função da bainha de mielina na transmissão do impulso nervoso?', 
 '["Gerar a sinapse química", "Atuar como isolante elétrico e acelerar o impulso", "Produzir neurotransmissores de contração", "Nutrir o corpo celular do neurônio"]', 1, 3, 2),

('Para desintoxicar o guerreiro envenenado por um esporo fúngico, o curandeiro estimula as células do fígado da vítima a realizar a metabolização de toxinas. Qual organela membranosa não-granulosa realiza a desintoxicação celular?', 
 '["Retículo endoplasmático liso (não-granuloso)", "Retículo endoplasmático rugoso (granuloso)", "Complexo de Golgi", "Lisossomo"]', 0, 3, 2),

('O mago realiza cruzamentos genéticos entre slimes azuis dominantes (AA) e slimes amarelos recessivos (aa). De acordo com a Primeira Lei de Mendel, qual a proporção fenotípica esperada na geração F2 após a autofecundação dos híbridos F1?', 
 '["3 dominantes para 1 recessivo", "1 dominante para 1 recessivo", "Todas recessivas", "9 dominantes para 7 recessivos"]', 0, 3, 2),

('O caçador arcano estuda uma planta carnívora da masmorra que fecha suas folhas rapidamente ao toque de um inseto. Que tipo de movimento vegetal não direcionado, desencadeado pelo toque físico, é esse?', 
 '["Fotonastia", "Geotropismo", "Sismonastia (ou tigmonastia)", "Quimiotropismo"]', 2, 3, 2),

('Um curandeiro prepara um soro contra o veneno de escorpião-golem injetando pequenas doses do veneno em um cavalo e depois extraindo os anticorpos prontos do sangue do animal. Essa imunização que fornece anticorpos prontos é classificada como:', 
 '["Imunização ativa (vacina)", "Imunização passiva (soro)", "Imunização celular inata", "Terapia gênica retroviral"]', 1, 3, 2),

('Um necromante revive tecidos mortos bloqueando a ação dos lisossomos celulares das vítimas para evitar a autodestruição celular. Qual o nome biológico da autodestruição de uma célula por meio da ruptura de seus próprios lisossomos?', 
 '["Autofagia", "Exocitose", "Autólise", "Plasmólise"]', 2, 3, 2),

('O slime de gelo sobrevive a temperaturas extremas graças a proteínas anticongelantes em sua membrana plasmática. A membrana plasmática celular é constituída principalmente por qual bicamada macromolecular?', 
 '["Bicamada fosfolipídica com proteínas inseridas", "Bicamada de carboidratos insolúveis", "Bicamada de ácidos nucleicos helicoidais", "Monocamada lipídica pura"]', 0, 3, 1),

('O mago da torre estuda vermes parasitas da masmorra que possuem corpo cilíndrico, triblásticos e pseudocelomados. A qual filo do reino animal esses vermes pertencem?', 
 '["Platelmintos", "Anelídeos", "Nematódeos (Nematelmintos)", "Moluscos"]', 2, 3, 2),

('Uma poção de super-oxigenação celular aumenta a taxa de respiração aeróbica celular. Qual molécula atua como aceitador final de elétrons na cadeia respiratória mitocondrial nas células humanas?', 
 '["Oxigênio gasoso (O₂)", "Glicose (C₆H₁₂O₆)", "Dióxido de carbono (CO₂)", "Água (H₂O)"]', 0, 3, 2),

('Para criar um mutante de rato-guerreiro gigante, o cientista manipula hormônios que aceleram o crescimento de ossos e cartilagens. Qual tecido conjuntivo é caracterizado por ser rígido, porém flexível, sem vasos sanguíneos nem nervos próprios?', 
 '["Tecido ósseo", "Tecido cartilaginoso", "Tecido epitelial de revestimento", "Tecido muscular estriado"]', 1, 3, 2),

('Um veneno gasoso espalhado no andar de Biologia inibe a atividade dos estômatos das plantas de mana. Qual a principal função das estruturas estomáticas nas folhas das plantas?', 
 '["Produzir clorofila para a fotossíntese", "Realizar trocas gasosas e transpiração", "Absorver água e sais minerais do solo", "Proteger a folha contra predadores herbívoros"]', 1, 3, 2);


-- ==========================================
-- ANDAR 1 - QUÍMICA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('Para neutralizar uma poção de ácido de slime (pH = 2) que corroeu as botas do guerreiro, qual reagente alquímico básico o curandeiro deve utilizar para aproximar o pH de 7 (neutro)?', 
 '["Uma solução alcalina (básica) de pH alto", "Outra poção ácida de pH 1", "Água destilada purificada apenas", "Um sal altamente insolúvel e ácido"]', 0, 1, 1),

('O Golem de Cristal derrete sob calor extremo em um processo físico onde a estrutura ordenada de silício passa do estado sólido para o estado líquido. Qual o nome dessa transição física de estado da matéria?', 
 '["Condensação", "Sublimação", "Fusão", "Vaporização"]', 2, 1, 1),

('Para sintetizar a lendária Pedra Filosofal, um alquimista mistura \"Sódio arcano\" (Na) altamente reativo com água mágica. O sódio puro reage violentamente liberando hidrogênio. Na tabela periódica, a qual família pertence o elemento Sódio?', 
 '["Halogênios", "Metais alcalinos", "Gases nobres", "Metais alcalino-terrosos"]', 1, 1, 2),

('A poção \"Sopro de Névoa\" é criada misturando cristais azuis de sal marinho em água purificada. O sal dissolve-se completamente, formando uma mistura homogênea transparente de fase única. Que tipo de mistura é essa?', 
 '["Mistura heterogênea", "Mistura coloidal", "Suspensão grosseira", "Mistura homogênea (solução)"]', 3, 1, 1),

('O mago arremessa uma runa de fogo que desencadeia a oxidação violenta de carvão mágico na presença de oxigênio gasoso (O₂), gerando gás carbônico (CO₂). Como é classificado esse tipo de reação química exotérmica?', 
 '["Reação de combustão", "Reação de eletrólise", "Reação de fotólise", "Reação de neutralização"]', 0, 1, 1),

('Uma poção ácida misteriosa possui alta concentração de íons de hidrogênio (H+). O que define o caráter ácido de uma substância de acordo com a teoria clássica de Arrhenius?', 
 '["Liberação de íons hidróxido (OH-) em solução aquosa", "Liberação de íons hidrogênio (H+) em solução aquosa", "Doação de um par de elétrons em qualquer meio", "Neutralização instantânea de qualquer sal neutro"]', 1, 1, 2),

('Para forjar uma armadura de Mithril indestrutível, o ferreiro funde cobre e estanho mágicos, formando uma liga metálica em que os átomos compartilham elétrons livres em uma \"nuvem eletrônica\". Que tipo de ligação química une esses metais?', 
 '["Ligação covalente", "Ligação iônica", "Ligação metálica", "Força de Van der Waals"]', 2, 1, 2),

('Um robô alquimista analisa o vapor condensado das masmorras e encontra monóxido de carbono (CO) e dióxido de carbono (CO₂). Ambos os gases são compostos por Carbono e Oxigênio, mas possuem diferentes propriedades. Qual lei ponderal explica que elementos combinam-se em proporções de números inteiros para formar diferentes compostos?', 
 '["Lei das Proporções Múltiplas (Dalton)", "Lei da Conservação das Massas (Lavoisier)", "Lei das Proporções Constantes (Proust)", "Lei de Volumetria (Gay-Lussac)"]', 0, 1, 3),

('Os magos usam o elemento \"Gás de Hélio arcano\" para flutuar baús pesados. O hélio é um gás extremamente estável que não reage com quase nada devido à sua camada de valência completa. Em qual família da tabela periódica o hélio está localizado?', 
 '["Metais de transição", "Halogênios", "Gases nobres", "Calcogênios"]', 2, 1, 1),

('O veneno corrosivo de um slime ácido é constituído por ácido clorídrico (HCl), em que o átomo de Hidrogênio e o de Cloro compartilham um par de elétrons devido à diferença de eletronegatividade entre eles. Que tipo de ligação química ocorre nessa molécula?', 
 '["Ligação metálica pura", "Ligação iônica forte", "Ligação covalente polar", "Ligação de hidrogênio dipolar"]', 2, 1, 2),

('Um dragão de gelo congela instantaneamente a umidade do ar, formando neve nas masmorras. A passagem do vapor de água diretamente para o estado sólido (gelo) é conhecida como:', 
 '["Sublimação inversa (ou Deposição)", "Solidificação clássica", "Condensação induzida", "Evaporação forçada"]', 0, 1, 2),

('O Mago de Fogo utiliza o mineral rúnico Hematita (Fe₂O₃) para extrair Ferro puro por meio de uma reação onde o Ferro ganha elétrons e diminui seu número de oxidação. Esse processo de ganho de elétrons é chamado de:', 
 '["Oxidação", "Redução", "Neutralização", "Sublimação"]', 1, 1, 3),

('Para acender a Forja de Hefesto, o guerreiro queima propano mágico (C₃H₈) gerando calor. Na reação balanceada: C₃H₈ + 5 O₂ -> 3 CO₂ + 4 H₂O, quantos mols de oxigênio (O₂) são necessários para queimar completamente 1 mol de propano?', 
 '["3 mols", "4 mols", "5 mols", "1 mol"]', 2, 1, 3),

('Para purificar um elixir mágico misturado com areia rúnica preta, o alquimista passa a solução por um papel de filtro arcano que retém a areia e deixa passar o líquido limpo. Qual o nome desse método físico de separação de misturas heterogêneas?', 
 '["Filtração", "Destilação simples", "Decantação molecular", "Centrifugação"]', 0, 1, 1),

('O mago misturou álcool mágico e água destilada. Sabendo que ambos possuem pontos de ebulição diferentes (78°C e 100°C), qual processo físico baseado na vaporização seguida de condensação ele deve usar para separar esses líquidos miscíveis?', 
 '["Filtração a vácuo", "Decantação fracionada", "Destilação fracionada", "Sublimação térmica"]', 2, 1, 2),

('Uma pedra rúnica de \"Cálcio arcano\" (Ca) reage com cloro para formar cloreto de cálcio. Sabendo que o cálcio é um metal alcalino-terroso que perde 2 elétrons e o cloro ganha 1 elétron, qual a fórmula molecular correta desse sal rúnico?', 
 '["CaCl", "CaCl₂", "Ca₂Cl", "Ca₂Cl₂"]', 1, 1, 2),

('Uma criatura de ferro da masmorra começa a sofrer oxidação lenta sob a humidade do ar, formando ferrugem vermelha (Fe₂O₃). Nesse processo químico natural de corrosão, qual agente atua sofrendo redução?', 
 '["O oxigênio do ar (O₂)", "O ferro metálico (Fe)", "A água das masmorras (H₂O)", "O dióxido de carbono (CO₂)"]', 0, 1, 2),

('Em um experimento de alquimia, o mago descobre que a adição de pó de ouro catalítico aumenta a velocidade da reação de síntese da poção sem ser consumido no processo. Qual a função de um catalisador em uma reação química?', 
 '["Aumentar a energia de ativação e a temperatura", "Diminuir a velocidade da reação química", "Diminuir a energia de ativação de caminhos alternativos", "Alterar a constante de equilíbrio químico final"]', 2, 1, 2),

('Uma poção alcalina estabilizada possui uma concentração de íons hidróxido (OH-) muito maior que a de íons hidrogênio (H+). Qual o valor aproximado do pH dessa poção na escala padrão a 25°C?', 
 '["pH menor que 7", "pH igual a 7", "pH maior que 7", "pH menor que 0"]', 2, 1, 2),

('O mago estuda o gás metano (CH₄) gerado pela decomposição de slimes orgânicos. A geometria molecular desse composto, em que o átomo de Carbono central liga-se covalentemente a 4 átomos de Hidrogênio, é descrita como:', 
 '["Linear", "Trigonal plana", "Tetraédrica", "Piramidal"]', 2, 1, 2),

('Um pergaminho descreve o \"Carbono arcano\" (C) em sua forma de grafite e em sua forma de diamante indestrutível. Embora compostos pelo mesmo elemento químico puro, possuem estruturas cristalinas diferentes. Esse fenômeno químico é chamado de:', 
 '["Isomeria espacial", "Alotropia", "Isotopia atômica", "Ressonância molecular"]', 1, 1, 2),

('Para resfriar uma poção fervente, o alquimista dissolve nitrato de amônio em água. O frasco fica extremamente gelado ao toque porque a dissolução absorve calor do ambiente. Reações que absorvem calor são classificadas como:', 
 '["Exotérmicas", "Isotérmicas", "Endotérmicas", "Adiabáticas"]', 2, 1, 2),

('Um slime de ácido sulfúrico (H₂SO₄) ataca o guerreiro. Sendo um ácido forte de Arrhenius bi-protonado, quantos hidrogênios ionizáveis ele libera por molécula em solução aquosa?', 
 '["1", "2", "3", "4"]', 1, 1, 2),

('A poção \"Luz de Fósforo\" brilha no escuro devido à combustão do fósforo branco (P₄). A ligação que ocorre entre os não-metais idênticos de fósforo se dá por compartilhamento equitativo de elétrons. Essa ligação é do tipo:', 
 '["Ligação covalente apolar", "Ligação covalente polar", "Ligação iônica forte", "Ligação metálica instável"]', 0, 1, 2),

('O mago da torre quer neutralizar 1 mol de ácido clorídrico (HCl) usando hidróxido de sódio (NaOH) na reação: HCl + NaOH -> NaCl + H₂O. Quantos mols de NaOH são necessários para neutralizar completamente o ácido?', 
 '["0,5 mol", "1 mol", "2 mols", "3 mols"]', 1, 1, 2),

('Uma liga rúnica leve para botas de voo é feita de Alumínio (Al). O átomo neutro de alumínio possui número atômico 13. Quantos elétrons ele possui em sua camada de valência (distribuição eletrônica 2, 8, 3)?', 
 '["1 elétron", "2 elétrons", "3 elétrons", "8 elétrons"]', 2, 1, 2);


-- ==========================================
-- ANDAR 2 - FÍSICA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('O mago lança uma bola de fogo (Fireball) horizontalmente do topo de uma plataforma com velocidade constante de 10 m/s. Se ela atinge o chão após 2 segundos (desconsiderando a resistência do ar), qual a distância horizontal percorrida pela bola de fogo?', 
 '["5 metros", "10 metros", "20 metros", "40 metros"]', 2, 2, 1),

('Para abrir um portal mágico de teletransporte, o mago canaliza energia elétrica através de runas dispostas em circuito paralelo. Se uma runa falha e se apaga (circuito aberto), o que acontece com a corrente elétrica nas outras runas do circuito paralelo?', 
 '["A corrente zera em todas as runas", "As outras runas continuam funcionando de forma independente", "A corrente nas outras runas cai pela metade", "Todas as runas queimam instantaneamente"]', 1, 2, 2),

('Uma runa de gravidade reversa aplica uma força constante para cima de 15 N em um bloco rúnico de massa 1 kg. Sabendo que a aceleração da gravidade local é de 10 m/s² para baixo, qual a aceleração resultante do bloco para cima? (F_res = m * a)', 
 '["5 m/s²", "15 m/s²", "10 m/s²", "25 m/s²"]', 0, 2, 2),

('O robô sentinela emite um feixe de luz mágica que reflete perfeitamente em um espelho de prata arcano. Se o ângulo de incidência do feixe luminoso em relação à normal é de 30°, qual o ângulo de reflexão do feixe segundo as leis da óptica geométrica?', 
 '["60°", "30°", "90°", "0°"]', 1, 2, 1),

('Um mago usa telecinese para empurrar um baú de tesouro com uma força constante de 50 N por uma distância de 4 metros na mesma direção da força. Qual o trabalho físico (W = F * d) realizado pela telecinese do mago sobre o baú?', 
 '["100 Joules", "12,5 Joules", "200 Joules", "50 Joules"]', 2, 2, 1),

('A poção \"Congelamento Rápido\" funciona absorvendo calor rapidamente da água líquida ao redor até que ela solidifique em gelo. O calor que provoca a mudança de estado físico sem alterar a temperatura do sistema é chamado de:', 
 '["Calor sensível", "Calor específico", "Calor de irradiação", "Calor latente"]', 3, 2, 2),

('Uma criatura mecânica flutua na água mágica da fonte da masmorra. Segundo o princípio de Arquimedes, o empuxo vertical para cima que atua sobre a criatura flutuante é igual ao:', 
 '["Volume total do corpo da criatura", "Peso do volume de líquido deslocado pela criatura", "Peso próprio da criatura no vácuo", "Dobro do volume submerso da criatura"]', 1, 2, 2),

('As bobinas de tesla da sala de robôs acumulam cargas elétricas estáticas de sinais opostos. De acordo com a Lei de Coulomb, se a distância entre duas cargas elétricas idênticas for duplicada, o que acontece com a força eletrostática entre elas?', 
 '["Fica quatro vezes menor (dividida por 4)", "Fica duas vezes menor (dividida por 2)", "Fica quatro vezes maior (multiplicada por 4)", "Permanece exatamente igual"]', 0, 2, 2),

('A espada rúnica do guerreiro brilha com calor incandescente. A transferência desse calor térmico através do contato direto da lâmina de metal quente com a carapaça de gelo de um slime ocorre principalmente por qual mecanismo físico?', 
 '["Radiação", "Convecção", "Condução", "Sublimação"]', 2, 2, 1),

('Um sino mágico de cristal é golpeado e emite um som agudo de alta frequência que ressoa pela torre. O som é uma onda mecânica longitudinal. Qual das seguintes afirmações sobre ondas sonoras é correta sob a física clássica?', 
 '["O som pode se propagar livremente no vácuo absoluto", "O som se propaga mais rapidamente em meios sólidos do que gasosos", "A velocidade do som independe da densidade do meio de propagação", "O som é uma onda eletromagnética de alta intensidade"]', 1, 2, 2),

('Uma flecha encantada é disparada com energia cinética inicial de 100 J. À medida que sobe para atingir um gárgula no topo da torre, ela perde velocidade e ganha altura. Desconsiderando atritos, em qual tipo de energia a energia cinética está se convertendo?', 
 '["Energia potencial gravitacional", "Energia potencial elástica", "Energia térmica radiante", "Energia química armazenada"]', 0, 2, 1),

('O mago estuda um prisma de cristal que divide um feixe de luz mágica branca em todas as cores do arco-íris. Esse fenômeno físico de separação de cores devido à variação do índice de refração com a frequência é chamado de:', 
 '["Reflexão total", "Difração rúnica", "Dispersão luminosa", "Polarização linear"]', 2, 2, 2),

('Um robô de patrulha movimenta-se em linha reta de acordo com a função horária da posição S(t) = 5 + 3t (no Sistema Internacional). Qual a velocidade linear de patrulha desse robô?', 
 '["5 m/s", "3 m/s", "8 m/s", "15 m/s"]', 1, 2, 1),

('Uma criatura robô do andar de Física colide elasticamente com outra criatura de mesma massa que estava parada. Segundo as leis de conservação física, o que ocorre com a quantidade de movimento total do sistema isolado após a colisão?', 
 '["Permanece constante (conserva-se)", "Reduz-se a zero instantaneamente", "Duplica de valor devido ao impacto", "Fica reduzida pela metade"]', 0, 2, 2),

('O mago usa um espelho côncavo mágico para projetar uma imagem real e invertida de uma runa brilhante na parede oposta da masmorra. Qual o tipo de lente ou espelho que pode gerar uma imagem real de um objeto real?', 
 '["Espelho côncavo (ou lente convergente)", "Espelho convexo (ou lente divergente)", "Espelho plano liso ordinário", "Lente divergente pura apenas"]', 0, 2, 2),

('Um robô sentinela carrega uma bateria de 12 Volts que alimenta seus circuitos com uma resistência elétrica de 4 Ohms. De acordo com a Primeira Lei de Ohm (U = R * I), qual a intensidade da corrente elétrica que flui pelo robô?', 
 '["3 Ampères", "48 Ampères", "0,33 Ampères", "8 Ampères"]', 0, 2, 2),

('Um mago aplica uma força constante de 20 N sobre um bloco de pedra rúnica de 2 kg que estava em repouso. Desconsiderando o atrito do solo, qual a aceleração sofrida pelo bloco de acordo com a Segunda Lei de Newton? (a = F / m)', 
 '["5 m/s²", "10 m/s²", "20 m/s²", "40 m/s²"]', 1, 2, 2),

('A bola de fogo lançada pelo mago viaja em linha reta com velocidade que aumenta uniformemente de 2 m/s para 14 m/s em um intervalo de tempo de 3 segundos. Qual a aceleração média dessa bola de fogo em Movimento Uniformemente Variado (MUV)?', 
 '["2 m/s²", "4 m/s²", "6 m/s²", "12 m/s²"]', 1, 2, 2),

('Um portal de gravidade do andar 3 puxa o guerreiro com uma força gravitacional de atração. Se a massa da Terra mágica é M e a do guerreiro é m, de acordo com a Lei da Gravitação Universal de Newton, a força gravitacional é:', 
 '["Inversamente proporcional ao quadrado da distância entre eles", "Diretamente proporcional à distância entre eles", "Independente do produto das massas", "Inversamente proporcional à distância simples"]', 0, 2, 2),

('O mago usa um guindaste hidráulico rúnico para elevar um golem pesado de pedra. O princípio físico por trás do elevador hidráulico, onde a pressão aplicada a um fluido incompressível é transmitida igualmente em todas as direções, é o:', 
 '["Princípio de Arquimedes", "Princípio de Pascal", "Princípio de Bernoulli", "Efeito Joule-Thomson"]', 1, 2, 2),

('A armadura eletrostática do mago repele flechas de energia metálica polarizadas. A lei física que define que cargas elétricas de mesmo sinal se repelem e de sinais opostos se atraem é a:', 
 '["Lei de Ampère", "Lei de Faraday-Lenz", "Lei de Coulomb (ou forças eletrostáticas)", "Lei de Gauss do magnetismo"]', 2, 2, 2),

('Um robô mecânico arrasta um baú pesado de 10 kg sobre o piso de pedra rugosa da masmorra. Se o coeficiente de atrito cinético entre o baú e o piso é 0,3 (adotando g = 10 m/s²), qual a força de atrito cinético oposta ao movimento? (F_at = mi * N)', 
 '["3 N", "30 N", "100 N", "0,3 N"]', 1, 2, 2),

('O calor emitido por uma runa de fogo irradia energia térmica através do espaço vazio da câmara de testes, aquecendo o ar. A transferência de calor que ocorre por meio de ondas eletromagnéticas (infravermelho) sem contato material é a:', 
 '["Condução", "Convecção", "Irradiação (ou Radiação térmica)", "Sublimação"]', 2, 2, 2),

('Um guerreiro gira um mangual rúnico em um movimento circular uniforme acima de sua cabeça. A aceleração direcionada para o centro da trajetória circular que mantém o mangual em órbita é a:', 
 '["Aceleração tangencial", "Aceleração centrípeta", "Aceleração gravitacional", "Aceleração angular"]', 1, 2, 2),

('Um feixe de luz de cura passa do ar para o cristal mágico da fonte. Ao mudar de meio, a luz sofre alteração em sua velocidade e direção de propagação. Esse fenômeno físico da luz é conhecido como:', 
 '["Reflexão", "Refração", "Difração", "Dispersão"]', 1, 2, 2),

('Uma runa de eletrocussão gera uma corrente elétrica que passa pela armadura do inimigo, aquecendo-a devido à resistência elétrica do metal. Esse efeito de transformação de energia elétrica em energia térmica é chamado de:', 
 '["Efeito Doppler", "Efeito Joule", "Efeito Fotoelétrico", "Efeito Hall"]', 1, 2, 2);

-- ==========================================
-- NOVAS QUESTÕES (72 adicionais para evitar repetição)
-- ==========================================

INSERT INTO perguntas (id, question, options, answer, andar_id, nivel_progresso) VALUES
(79, 'Uma poção de cura evapora quando aquecida, passando do estado líquido para o estado gasoso. Qual o nome dessa mudança de estado físico?', '["Vaporização", "Condensação", "Fusão", "Sublimação"]', 0, 1, 1),
(80, 'Ao misturar pó de esmeralda e água rúnica, o pó deposita-se no fundo sem se dissolver. Que tipo de mistura heterogênea é essa?', '["Mistura homogênea", "Solução gasosa", "Suspensão", "Coloide"]', 2, 1, 1),
(81, 'Qual destas substâncias mágicas é considerada um elemento químico puro, não podendo ser decomposta por meios químicos?', '["Água pura", "Ouro arcano (Au)", "Sal de rocha", "Bronze rúnico"]', 1, 1, 1),
(82, 'O fogo de um dragão consome madeira mágica, transformando-a em cinzas e fumaça. Esse processo é considerado:', '["Uma transformação física", "Uma transformação química", "Uma fusão simples", "Um processo reversível"]', 1, 1, 1),
(83, 'Um aprendiz de alquimista usa uma escala de pH para medir a acidez de um slime de fogo (pH = 1). Essa poção é altamente:', '["Ácida", "Básica", "Neutra", "Alcalina"]', 0, 1, 1),
(84, 'Qual é o símbolo químico rúnico que representa o elemento Oxigênio na tabela periódica de alquimia?', '["Ox", "O", "Op", "On"]', 1, 1, 1),
(85, 'Que propriedade da água mágica permite que insetos da masmorra caminhem sobre ela sem afundar?', '["Tensão superficial", "Viscosidade extrema", "Densidade nula", "Capilaridade reversa"]', 0, 1, 1),
(86, 'Se misturarmos óleo de dragão e água purificada, eles não se misturam e formam duas fases. Essa mistura é classificada como:', '["Homogênea", "Solução", "Heterogênea", "Azeotrópica"]', 2, 1, 1),
(87, 'Uma ligação química ocorre quando dois átomos compartilham elétrons de valência de forma igualitária para obter estabilidade. Essa ligação é chamada de:', '["Ligação iônica", "Ligação metálica", "Ligação covalente", "Força de dispersão"]', 2, 1, 2),
(88, 'Qual partícula subatômica, localizada no núcleo do átomo rúnico, possui carga elétrica positiva?', '["Elétron", "Próton", "Nêutron", "Pósitron"]', 1, 1, 2),
(89, 'Na reação química de combustão de mana, reagentes se transformam em produtos. A Lei de Lavoisier afirma que, em um sistema fechado:', '["A massa total se conserva", "A massa dos produtos dobra", "A energia vira matéria pura", "O volume permanece fixo"]', 0, 1, 2),
(90, 'A distribuição eletrônica de um átomo de mana determina suas propriedades. Em qual camada do átomo ocorrem as ligações químicas?', '["Camada interna K", "Núcleo atômico", "Camada de valência", "Nuvem de nêutrons"]', 2, 1, 2),
(91, 'Uma solução mágica tem concentração de 20 g/L de sal rúnico. Se evaporarmos metade da água, a nova concentração será:', '["10 g/L", "20 g/L", "40 g/L", "80 g/L"]', 2, 1, 2),
(92, 'Que família de elementos na tabela periódica possui a camada de valência completa e é extremamente estável quimicamente?', '["Metais alcalinos", "Halogênios", "Gases nobres", "Calcogênios"]', 2, 1, 2),
(93, 'Qual é o pH de uma poção perfeitamente neutra, como a água destilada rúnica usada para diluir venenos?', '["pH = 0", "pH = 7", "pH = 14", "pH = 5"]', 1, 1, 2),
(94, 'A atração que um átomo exerce sobre os elétrons em uma ligação química covalente é conhecida como:', '["Eletronegatividade", "Potencial de ionização", "Afinidade eletrônica", "Raio atômico"]', 0, 1, 2),
(95, 'A síntese de mana azul libera grande quantidade de calor para o ambiente. Esse tipo de reação química é classificada como:', '["Exotérmica", "Endotérmica", "Isotérmica", "Catalítica"]', 0, 1, 3),
(96, 'Em uma reação de oxirredução rúnica, o agente redutor é a espécie química que:', '["Ganha elétrons e se reduz", "Perde elétrons e sofre oxidação", "Não sofre alteração no NOX", "Catalisa a velocidade da reação"]', 1, 1, 3),
(97, 'De acordo com a estequiometria alquímica, se 1 mol de reagente A produz 2 mols de produto B, quantos mols de B são produzidos com 3 mols de A?', '["3 mols", "4 mols", "6 mols", "9 mols"]', 2, 1, 3),
(98, 'Qual das seguintes fórmulas moleculares representa um hidrocarboneto alcano simples na química orgânica?', '["C2H4", "CH4 (Metano)", "C2H2", "CH3OH"]', 1, 1, 3),
(99, 'O princípio de Le Chatelier afirma que, se aplicarmos uma perturbação a um sistema em equilíbrio químico, o sistema se deslocará para:', '["Minimizar a perturbação aplicada", "Maximizar a perturbação aplicada", "Cessar qualquer reação direta", "Aumentar a constante de equilíbrio"]', 0, 1, 3),
(100, 'Qual o nome da constante que relaciona a velocidade das reações direta e inversa quando um sistema rúnico atinge o equilíbrio químico?', '["Constante de Faraday", "Constante de Avogadro", "Constante de equilíbrio (Kc)", "Constante de Planck"]', 2, 1, 3),
(101, 'A lei dos gases ideais (P * V = n * R * T) indica que, mantendo a temperatura constante, se duplicarmos a pressão de um gás de mana, seu volume:', '["Duplicará também", "Cairá pela metade", "Aumentará quatro vezes", "Permanecerá constante"]', 1, 1, 3),
(102, 'Qual é a hibridização do átomo de carbono na molécula de dióxido de carbono (CO₂), que possui duas ligações duplas?', '["sp3", "sp2", "sp", "sp3d"]', 2, 1, 3),
(103, 'Um guerreiro corre com velocidade constante de 5 m/s. Qual a distância percorrida por ele após 10 segundos de corrida?', '["2 metros", "15 metros", "50 metros", "100 metros"]', 2, 2, 1),
(104, 'Qual a força que atrai todos os objetos na masmorra em direção ao centro da terra mágica, dando-lhes peso?', '["Força centrífuga", "Força gravitacional", "Força magnética", "Força elástica"]', 1, 2, 1),
(105, 'Uma runa de aceleração aumenta a velocidade do jogador uniformemente. A taxa de variação da velocidade no tempo é chamada de:', '["Velocidade média", "Deslocamento", "Aceleração", "Trabalho mecânico"]', 2, 2, 1),
(106, 'Se um bloco de pedra mágica tem massa de 10 kg na masmorra, qual será a sua massa se for levado para a Lua rúnica?', '["Zero", "10 kg", "1,6 kg", "60 kg"]', 1, 2, 1),
(107, 'Uma pedra de fogo possui energia armazenada devido à sua posição elevada no topo de uma torre. Essa energia é classificada como:', '["Energia cinética", "Energia térmica pura", "Energia potencial gravitacional", "Energia química rúnica"]', 2, 2, 1),
(108, 'O fluxo ordenado de elétrons através de um fio condutor rúnico é a definição de qual grandeza física?', '["Tensão elétrica", "Resistência", "Corrente elétrica", "Potência rúnica"]', 2, 2, 1),
(109, 'O eco em uma caverna ocorre quando as ondas sonoras colidem com a parede e retornam ao emissor. Esse fenômeno é a:', '["Reflexão", "Refração", "Difração", "Polarização"]', 0, 2, 1),
(110, 'Qual unidade do Sistema Internacional (SI) é utilizada para medir a força aplicada por um guerreiro ao empurrar um bloco?', '["Joule (J)", "Newton (N)", "Watt (W)", "Pascal (Pa)"]', 1, 2, 1),
(111, 'A Primeira Lei de Newton, também conhecida como Lei da Inércia, afirma que um objeto em repouso tende a:', '["Mover-se aceleradamente", "Permanecer em repouso", "Desacelerar aos poucos", "Mudar sua trajetória"]', 1, 2, 2),
(112, 'Um circuito rúnico possui duas resistências ligadas em série. Se uma das resistências queimar, o que ocorre com a corrente elétrica no circuito?', '["A corrente é interrompida por completo", "A corrente continua funcionando normal", "A corrente duplica de intensidade", "A corrente passa a piscar"]', 0, 2, 2),
(113, 'A Primeira Lei de Ohm estabelece que a diferença de potencial (U) é igual ao produto da resistência (R) pela:', '["Potência elétrica", "Frequência de oscilação", "Corrente elétrica (I)", "Capacitância rúnica"]', 2, 2, 2),
(114, 'O calor gerado por uma poção de fogo se espalha pela sala através do movimento de massas de ar quente subindo e ar frio descendo. Esse processo é a:', '["Condução", "Irradiação", "Convecção", "Sublimação"]', 2, 2, 2),
(115, 'A velocidade da luz rúnica diminui ao passar do ar para a água de uma fonte, alterando sua direção. Esse fenômeno é a:', '["Reflexão", "Refração", "Difração", "Dispersão"]', 1, 2, 2),
(116, 'De acordo com a Segunda Lei de Newton (F = m * a), se aplicarmos uma força de 30 N em um bloco de 5 kg, qual a aceleração resultante?', '["6 m/s²", "150 m/s²", "25 m/s²", "35 m/s²"]', 0, 2, 2),
(117, 'A distância entre dois picos consecutivos de uma onda eletromagnética rúnica é chamada de:', '["Período de onda", "Frequência linear", "Comprimento de onda", "Amplitude rúnica"]', 2, 2, 2),
(118, 'O trabalho realizado por um golem para empurrar um baú por uma distância de 5 metros com uma força constante de 20 N é de:', '["4 Joules", "100 Joules", "25 Joules", "15 Joules"]', 1, 2, 2),
(119, 'Em uma colisão perfeitamente inelástica entre dois carrinhos de mina de mesma massa, após o impacto os carrinhos se movem:', '["Em direções opostas", "Juntos com a mesma velocidade final", "Parados imediatamente", "Uma velocidade que dobra de valor"]', 1, 2, 3),
(120, 'A força necessária para manter um robô de patrulha em movimento circular uniforme em uma pista arredondada é a força:', '["Força tangencial", "Força centrípeta", "Força eletrostática", "Força elástica de tração"]', 1, 2, 3),
(121, 'A Lei da Gravitação Universal de Newton afirma que a força de atração entre duas massas é inversamente proporcional a:', '["Ao quadrado da distância entre elas", "À distância simples linear", "Ao produto de suas massas", "À constante de gravidade"]', 0, 2, 3),
(122, 'De acordo com a Lei de Faraday-Lenz do eletromagnetismo, uma variação no fluxo magnético através de uma bobina rúnica induz uma:', '["Resistência elétrica alta", "Força eletromotriz (tensão)", "Carga estática de prótons", "Frequência de ressonância"]', 1, 2, 3),
(123, 'A equação de Bernoulli para fluidos mágicos em movimento baseia-se em qual princípio físico fundamental?', '["Conservação da energia mecânica", "Conservação de cargas elétricas", "Inércia das massas viscosas", "Princípio da conservação de massa"]', 0, 2, 3),
(124, 'Qual o tipo de espelho esférico rúnico que sempre produz imagens virtuais, direitas e menores que o objeto real?', '["Espelho côncavo", "Espelho convexo", "Espelho plano", "Espelho parabólico"]', 1, 2, 3),
(125, 'Uma onda rúnica de rádio tem frequência de 100 MHz. Sabendo que a velocidade da onda é 300.000 km/s, qual seu comprimento de onda?', '["3 metros", "300 metros", "30 metros", "0,3 metros"]', 0, 2, 3),
(126, 'Se um circuito em paralelo possui três runas de luz idênticas e uma delas queima, o que ocorre com o brilho das outras duas runas?', '["Apagam-se instantaneamente", "Permanecem brilhando com a mesma intensidade", "Ficam mais fracas", "Brilham com o dobro da força"]', 1, 2, 3),
(127, 'Qual organela celular rúnica, presente nas células dos magos, é responsável pela geração de energia na forma de ATP?', '["Ribossomo", "Lisossomo", "Mitocôndria", "Peroxissomo"]', 2, 3, 1),
(128, 'O menor nível de organização biológica que é considerado vivo por si só e possui membrana, citoplasma e material genético é a:', '["Molécula", "Célula", "Organela", "Tecido rúnico"]', 1, 3, 1),
(129, 'De acordo com a biologia celular, as células que possuem núcleo delimitado por membrana carioteca são classificadas como:', '["Procarióticas", "Eucarióticas", "Arqueas", "Vírus"]', 1, 3, 1),
(130, 'Qual molécula de fita dupla armazena a informação genética hereditária dos seres da masmorra?', '["RNA mensageiro", "Ácido Desoxirribonucleico (DNA)", "Trifosfato de adenosina (ATP)", "Polipeptídeo cristalino"]', 1, 3, 1),
(131, 'Em uma cadeia alimentar simples, as plantas de mana que produzem seu próprio alimento através da luz solar são os:', '["Consumidores", "Produtores", "Decompositores", "Predadores"]', 1, 3, 1),
(132, 'O processo pelo qual as plantas de mana convertem água e gás carbônico em glicose usando luz solar é a:', '["Respiração celular", "Fotossíntese", "Fermentação lática", "Transpiração estomática"]', 1, 3, 1),
(133, 'Qual organela rúnica realiza a síntese de proteínas a partir das instruções do RNA mensageiro?', '["Ribossomo", "Nucléolo", "Peroxissomo", "Lisossomo"]', 0, 3, 1),
(134, 'Qual sistema do corpo do guerreiro é responsável por bombear o sangue e distribuir oxigênio para os músculos?', '["Sistema nervoso", "Sistema respiratório", "Sistema cardiovascular (circulatório)", "Sistema digestório"]', 2, 3, 1),
(135, 'Que processo de divisão celular gera quatro células-filhas haploides (com metade do número de cromossomos) para a reprodução sexuada?', '["Mitose", "Meiose", "Fissão binária", "Esporulação"]', 1, 3, 2),
(136, 'A Primeira Lei de Mendel, ou Lei da Segregação dos Fatores, afirma que cada característica hereditária é determinada por:', '["Dois alelos que se separam na formação dos gametas", "Múltiplos genes que interagem de forma epistática", "Um único alelo materno sempre dominante", "Fatores adquiridos durante a vida do troll"]', 0, 3, 2),
(137, 'O mecanismo evolucionário proposto por Charles Darwin, em que os indivíduos mais adaptados ao ambiente sobrevivem e se reproduzem, é a:', '["Deriva genética", "Seleção natural", "Mutação induzida", "Lei do uso e desuso"]', 1, 3, 2),
(138, 'Qual das seguintes organelas celulares é responsável por realizar a digestão intracelular e reciclagem de componentes velhos?', '["Mitocôndria", "Retículo endoplasmático", "Lisossomo", "Ribossomo"]', 2, 3, 2),
(139, 'Durante a respiração celular aeróbica, em qual etapa ocorre a maior parte da produção de ATP dentro da mitocôndria?', '["Glicólise citoplasmática", "Ciclo de Krebs", "Fosforilação oxidativa (cadeia respiratória)", "Fermentação alcoólica"]', 2, 3, 2),
(140, 'As bactérias da masmorra se reproduzem assexuadamente dividindo-se em duas células idênticas. Esse processo é a:', '["Conjugação", "Partenogênese", "Bipartição (ou fissão binária)", "Esporulação"]', 2, 3, 2),
(141, 'Qual tecido do corpo humano é responsável por transmitir sinais elétricos rápidos e coordenar os movimentos do guerreiro?', '["Tecido epitelial", "Tecido conjuntivo", "Tecido nervoso", "Tecido muscular liso"]', 2, 3, 2),
(142, 'Que classe de macromoléculas biológicas atua como catalisadores de reações químicas, acelerando processos vitais?', '["Enzimas (proteínas)", "Lipídios saturados", "Polissacarídeos fibrosos", "Ácidos nucleicos puros"]', 0, 3, 2),
(143, 'O estudo de modificações na expressão gênica que não alteram a sequência de bases do DNA é conhecido como:', '["Epigenética", "Mutagênese", "Clonagem molecular", "Hibridização cromossômica"]', 0, 3, 3),
(144, 'Qual enzima rúnica é responsável por abrir a dupla-hélice de DNA durante o processo de replicação celular?', '["DNA ligase", "Helicase", "DNA polimerase", "Amilase"]', 1, 3, 3),
(145, 'No processo de síntese proteica, o RNA transportador carrega aminoácidos até o ribossomo pareando seu anticódon com o:', '["Promotor rúnico", "Histona do DNA", "Códon do RNA mensageiro", "Ribozima citoplasmática"]', 2, 3, 3),
(146, 'A bioacumulação de toxinas de metal mágico ao longo dos níveis tróficos de uma cadeia alimentar é maior em qual nível?', '["Produtores primários", "Consumidores primários", "Consumidores terciários (predadores de topo)", "Decompositores biológicos"]', 2, 3, 3),
(147, 'Qual tipo de imunidade é ativada quando o corpo do guerreiro produz seus próprios anticorpos em resposta a uma vacina ou antígeno?', '["Imunidade passiva", "Imunidade ativa", "Imunidade cruzada inata", "Terapia celular adaptativa"]', 1, 3, 3),
(148, 'As histonas são proteínas fundamentais no núcleo celular eucariótico que têm a função de:', '["Realizar a síntese de peptídeos", "Compactar e organizar a molécula de DNA em cromatina", "Degradar toxinas citoplasmáticas", "Atuar como canais de membrana"]', 1, 3, 3),
(149, 'Qual tecido conjuntivo humano é caracterizado por possuir matriz extracelular calcificada e alta rigidez estrutural?', '["Tecido cartilaginoso", "Tecido ósseo", "Tecido epitelial", "Tecido muscular estriado"]', 1, 3, 3),
(150, 'No ciclo celular, em qual subfase da intérfase ocorre a duplicação completa do material genético (DNA) da célula?', '["Fase G1", "Fase S", "Fase G2", "Mitose (Fase M)"]', 1, 3, 3);
