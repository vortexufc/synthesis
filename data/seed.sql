-- Seed file for the "perguntas" table
-- Total of 78 thematic questions (26 Biology, 26 Chemistry, 26 Physics)
-- Floor IDs: 1 = Biologia, 2 = Química, 3 = Física

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
-- ANDAR 1 - BIOLOGIA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('Um jovem mago percebeu que, ao conjurar um feitiço de cura, a energia regenerativa estimula a divisão de células somáticas da pele ferida do guerreiro. Que processo celular de divisão de células idênticas o feitiço acelerou?', 
 '["Mitose", "Meiose", "Fissão binária", "Esporulação"]', 0, 1, 1),

('O Slime Verde da masmorra absorve nutrientes digerindo matéria orgânica externamente antes de a absorver. De acordo com a biologia, que tipo de nutrição esse ser compartilha com os fungos terrestres?', 
 '["Autotrófica por fotossíntese", "Heterotrófica por absorção", "Quimiolitoautotrófica", "Autotrófica por quimiossíntese"]', 1, 1, 1),

('Nas estufas arcanas da torre, as plantas de mana purificam o ar utilizando a luz solar para sintetizar glicose a partir de dióxido de carbono gasoso e água. Que organela celular é responsável por essa conversão mágica?', 
 '["Mitocôndria", "Complexo de Golgi", "Cloroplasto", "Lisossomo"]', 2, 1, 1),

('Uma poção vigorizante atua fornecendo alta carga de energia celular direta na forma de ATP (Adenosina Trifosfato). Em qual organela celular a maior parte do ATP é sintetizada por meio da respiração celular?', 
 '["Ribossomo", "Lisossomo", "Retículo endoplasmático", "Mitocôndria"]', 3, 1, 2),

('Um alquimista estuda o veneno de uma aranha da masmorra e descobre que ele bloqueia a síntese de proteínas nas células da vítima. Qual organela celular responsável pela tradução do RNAm foi paralisada pelo veneno?', 
 '["Ribossomo", "Nucléolo", "Peroxissomo", "Centríolo"]', 0, 1, 2),

('Para criar um clone estável de um homúnculo, o mago precisa extrair a molécula dupla-hélice que carrega a informação genética completa da criatura. Qual é o nome dessa molécula biológica?', 
 '["RNA mensageiro", "Ácido Desoxirribonucleico (DNA)", "Trifosfato de adenosina (ATP)", "Polipeptídeo cristalino"]', 1, 1, 1),

('Os slimes gigantes da torre se reproduzem dividindo-se ao meio em dois slimes idênticos menores, sem troca de material genético. Esse método de reprodução assexuada é análogo a qual processo de reprodução de bactérias?', 
 '["Conjugação bacteriana", "Brotamento mitótico", "Divisão binária (ou cissiparidade)", "Partenogênese induzida"]', 2, 1, 2),

('Em uma simulação de ecossistema na torre, o mago observa que os robôs coletores (consumidores secundários) acumulam toxinas de metais mágicos em maior concentração que os slimes coletores (consumidores primários). Esse fenômeno ecológico é chamado de:', 
 '["Nicho ecológico", "Sucessão ecológica", "Eutrofização controlada", "Magnificação trófica (ou bioacumulação)"]', 3, 1, 3),

('As células do Mago Negro possuem uma parede celular rígida externa que protege contra flutuações de pressão osmótica na água circundante. De acordo com a biologia celular vegetal, qual substância carboidrato compõe essa estrutura de proteção?', 
 '["Celulose", "Glicogênio", "Quitina", "Amido"]', 0, 1, 2),

('O dragão de fogo da torre consome grandes quantidades de lipídios da masmorra para armazenar energia de longo prazo sob a forma de gordura térmica sob suas escamas. Qual das seguintes funções melhor descreve os lipídios na biologia?', 
 '["Catalisadores enzimáticos exclusivos", "Reserva de energia e isolamento térmico", "Transportadores rápidos de oxigênio no sangue", "Estrutura básica do material genético principal"]', 1, 1, 1),

('Ao conjurar um feitiço de envelhecimento rápido sobre um troll, o mago altera a expressão do material genético sem modificar a sequência de bases nitrogenadas do DNA do troll. Esse ramo de estudo da genética é conhecido como:', 
 '["Epigenética", "Mutagênese direcionada", "Clonagem molecular", "Transgênese cromossômica"]', 0, 1, 3),

('Uma poção de rejuvenescimento celular contém uma enzima que repara as extremidades repetitivas dos cromossomos, que encurtam a cada divisão celular rúnica. Qual o nome biológico dessas extremidades protetoras do DNA?', 
 '["Cinetócoros", "Telômeros", "Centrômeros", "Histonas"]', 1, 1, 3),

('Um caçador arcano analisa o sangue azul de um caranguejo da masmorra e nota que ele transporta oxigênio usando cobre em vez de ferro. Que proteína respiratória de cor azulada realiza essa função na biologia?', 
 '["Hemoglobina", "Mioglobina", "Hemocianina", "Clorofila"]', 2, 1, 3),

('O mago observa que, após um incêndio florestal provocado por uma bola de fogo, liquens arcanos e briófitas (musgos) são os primeiros a colonizar as rochas expostas na masmorra. Qual o termo ecológico para essa primeira comunidade colonizadora?', 
 '["Comunidade pioneira (ou ecese)", "Comunidade clímax", "Comunidade de transição (sere)", "Comunidade degradada"]', 0, 1, 2),

('Uma poção concentrada ativa um morcego da masmorra a usar ecolocalização para caçar no escuro, emitindo ondas sonoras que colidem em obstáculos e retornam. Qual o nome biológico desse sentido sensorial adaptativo?', 
 '["Magnetorecepção", "Ecolocalização (ou biossonar)", "Quimiorecepção", "Eletrorecepção"]', 1, 1, 1),

('O veneno de uma serpente arcana dissolve a bainha de mielina dos neurônios do jogador, diminuindo drasticamente a velocidade de propagação dos impulsos nervosos. Qual a função da bainha de mielina na transmissão do impulso nervoso?', 
 '["Gerar a sinapse química", "Atuar como isolante elétrico e acelerar o impulso", "Produzir neurotransmissores de contração", "Nutrir o corpo celular do neurônio"]', 1, 1, 2),

('Para desintoxicar o guerreiro envenenado por um esporo fúngico, o curandeiro estimula as células do fígado da vítima a realizar a metabolização de toxinas. Qual organela membranosa não-granulosa realiza a desintoxicação celular?', 
 '["Retículo endoplasmático liso (não-granuloso)", "Retículo endoplasmático rugoso (granuloso)", "Complexo de Golgi", "Lisossomo"]', 0, 1, 2),

('O mago realiza cruzamentos genéticos entre slimes azuis dominantes (AA) e slimes amarelos recessivos (aa). De acordo com a Primeira Lei de Mendel, qual a proporção fenotípica esperada na geração F2 após a autofecundação dos híbridos F1?', 
 '["3 dominantes para 1 recessivo", "1 dominante para 1 recessivo", "Todas recessivas", "9 dominantes para 7 recessivos"]', 0, 1, 2),

('O caçador arcano estuda uma planta carnívora da masmorra que fecha suas folhas rapidamente ao toque de um inseto. Que tipo de movimento vegetal não direcionado, desencadeado pelo toque físico, é esse?', 
 '["Fotonastia", "Geotropismo", "Sismonastia (ou tigmonastia)", "Quimiotropismo"]', 2, 1, 2),

('Um curandeiro prepara um soro contra o veneno de escorpião-golem injetando pequenas doses do veneno em um cavalo e depois extraindo os anticorpos prontos do sangue do animal. Essa imunização que fornece anticorpos prontos é classificada como:', 
 '["Imunização ativa (vacina)", "Imunização passiva (soro)", "Imunização celular inata", "Terapia gênica retroviral"]', 1, 1, 2),

('Um necromante revive tecidos mortos bloqueando a ação dos lisossomos celulares das vítimas para evitar a autodestruição celular. Qual o nome biológico da autodestruição de uma célula por meio da ruptura de seus próprios lisossomos?', 
 '["Autofagia", "Exocitose", "Autólise", "Plasmólise"]', 2, 1, 2),

('O slime de gelo sobrevive a temperaturas extremas graças a proteínas anticongelantes em sua membrana plasmática. A membrana plasmática celular é constituída principalmente por qual bicamada macromolecular?', 
 '["Bicamada fosfolipídica com proteínas inseridas", "Bicamada de carboidratos insolúveis", "Bicamada de ácidos nucleicos helicoidais", "Monocamada lipídica pura"]', 0, 1, 1),

('O mago da torre estuda vermes parasitas da masmorra que possuem corpo cilíndrico, triblásticos e pseudocelomados. A qual filo do reino animal esses vermes pertencem?', 
 '["Platelmintos", "Anelídeos", "Nematódeos (Nematelmintos)", "Moluscos"]', 2, 1, 2),

('Uma poção de super-oxigenação celular aumenta a taxa de respiração aeróbica celular. Qual molécula atua como aceitador final de elétrons na cadeia respiratória mitocondrial nas células humanas?', 
 '["Oxigênio gasoso (O₂)", "Glicose (C₆H₁₂O₆)", "Dióxido de carbono (CO₂)", "Água (H₂O)"]', 0, 1, 2),

('Para criar um mutante de rato-guerreiro gigante, o cientista manipula hormônios que aceleram o crescimento de ossos e cartilagens. Qual tecido conjuntivo é caracterizado por ser rígido, porém flexível, sem vasos sanguíneos nem nervos próprios?', 
 '["Tecido ósseo", "Tecido cartilaginoso", "Tecido epitelial de revestimento", "Tecido muscular estriado"]', 1, 1, 2),

('Um veneno gasoso espalhado no andar de Biologia inibe a atividade dos estômatos das plantas de mana. Qual a principal função das estruturas estomáticas nas folhas das plantas?', 
 '["Produzir clorofila para a fotossíntese", "Realizar trocas gasosas e transpiração", "Absorver água e sais minerais do solo", "Proteger a folha contra predadores herbívoros"]', 1, 1, 2);


-- ==========================================
-- ANDAR 2 - QUÍMICA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('Para neutralizar uma poção de ácido de slime (pH = 2) que corroeu as botas do guerreiro, qual reagente alquímico básico o curandeiro deve utilizar para aproximar o pH de 7 (neutro)?', 
 '["Uma solução alcalina (básica) de pH alto", "Outra poção ácida de pH 1", "Água destilada purificada apenas", "Um sal altamente insolúvel e ácido"]', 0, 2, 1),

('O Golem de Cristal derrete sob calor extremo em um processo físico onde a estrutura ordenada de silício passa do estado sólido para o estado líquido. Qual o nome dessa transição física de estado da matéria?', 
 '["Condensação", "Sublimação", "Fusão", "Vaporização"]', 2, 2, 1),

('Para sintetizar a lendária Pedra Filosofal, um alquimista mistura \"Sódio arcano\" (Na) altamente reativo com água mágica. O sódio puro reage violentamente liberando hidrogênio. Na tabela periódica, a qual família pertence o elemento Sódio?', 
 '["Halogênios", "Metais alcalinos", "Gases nobres", "Metais alcalino-terrosos"]', 1, 2, 2),

('A poção \"Sopro de Névoa\" é criada misturando cristais azuis de sal marinho em água purificada. O sal dissolve-se completamente, formando uma mistura homogênea transparente de fase única. Que tipo de mistura é essa?', 
 '["Mistura heterogênea", "Mistura coloidal", "Suspensão grosseira", "Mistura homogênea (solução)"]', 3, 2, 1),

('O mago arremessa uma runa de fogo que desencadeia a oxidação violenta de carvão mágico na presença de oxigênio gasoso (O₂), gerando gás carbônico (CO₂). Como é classificado esse tipo de reação química exotérmica?', 
 '["Reação de combustão", "Reação de eletrólise", "Reação de fotólise", "Reação de neutralização"]', 0, 2, 1),

('Uma poção ácida misteriosa possui alta concentração de íons de hidrogênio (H+). O que define o caráter ácido de uma substância de acordo com a teoria clássica de Arrhenius?', 
 '["Liberação de íons hidróxido (OH-) em solução aquosa", "Liberação de íons hidrogênio (H+) em solução aquosa", "Doação de um par de elétrons em qualquer meio", "Neutralização instantânea de qualquer sal neutro"]', 1, 2, 2),

('Para forjar uma armadura de Mithril indestrutível, o ferreiro funde cobre e estanho mágicos, formando uma liga metálica em que os átomos compartilham elétrons livres em uma \"nuvem eletrônica\". Que tipo de ligação química une esses metais?', 
 '["Ligação covalente", "Ligação iônica", "Ligação metálica", "Força de Van der Waals"]', 2, 2, 2),

('Um robô alquimista analisa o vapor condensado das masmorras e encontra monóxido de carbono (CO) e dióxido de carbono (CO₂). Ambos os gases são compostos por Carbono e Oxigênio, mas possuem diferentes propriedades. Qual lei ponderal explica que elementos combinam-se em proporções de números inteiros para formar diferentes compostos?', 
 '["Lei das Proporções Múltiplas (Dalton)", "Lei da Conservação das Massas (Lavoisier)", "Lei das Proporções Constantes (Proust)", "Lei de Volumetria (Gay-Lussac)"]', 0, 2, 3),

('Os magos usam o elemento \"Gás de Hélio arcano\" para flutuar baús pesados. O hélio é um gás extremamente estável que não reage com quase nada devido à sua camada de valência completa. Em qual família da tabela periódica o hélio está localizado?', 
 '["Metais de transição", "Halogênios", "Gases nobres", "Calcogênios"]', 2, 2, 1),

('O veneno corrosivo de um slime ácido é constituído por ácido clorídrico (HCl), em que o átomo de Hidrogênio e o de Cloro compartilham um par de elétrons devido à diferença de eletronegatividade entre eles. Que tipo de ligação química ocorre nessa molécula?', 
 '["Ligação metálica pura", "Ligação iônica forte", "Ligação covalente polar", "Ligação de hidrogênio dipolar"]', 2, 2, 2),

('Um dragão de gelo congela instantaneamente a umidade do ar, formando neve nas masmorras. A passagem do vapor de água diretamente para o estado sólido (gelo) é conhecida como:', 
 '["Sublimação inversa (ou Deposição)", "Solidificação clássica", "Condensação induzida", "Evaporação forçada"]', 0, 2, 2),

('O Mago de Fogo utiliza o mineral rúnico Hematita (Fe₂O₃) para extrair Ferro puro por meio de uma reação onde o Ferro ganha elétrons e diminui seu número de oxidação. Esse processo de ganho de elétrons é chamado de:', 
 '["Oxidação", "Redução", "Neutralização", "Sublimação"]', 1, 2, 3),

('Para acender a Forja de Hefesto, o guerreiro queima propano mágico (C₃H₈) gerando calor. Na reação balanceada: C₃H₈ + 5 O₂ -> 3 CO₂ + 4 H₂O, quantos mols de oxigênio (O₂) são necessários para queimar completamente 1 mol de propano?', 
 '["3 mols", "4 mols", "5 mols", "1 mol"]', 2, 2, 3),

('Para purificar um elixir mágico misturado com areia rúnica preta, o alquimista passa a solução por um papel de filtro arcano que retém a areia e deixa passar o líquido limpo. Qual o nome desse método físico de separação de misturas heterogêneas?', 
 '["Filtração", "Destilação simples", "Decantação molecular", "Centrifugação"]', 0, 2, 1),

('O mago misturou álcool mágico e água destilada. Sabendo que ambos possuem pontos de ebulição diferentes (78°C e 100°C), qual processo físico baseado na vaporização seguida de condensação ele deve usar para separar esses líquidos miscíveis?', 
 '["Filtração a vácuo", "Decantação fracionada", "Destilação fracionada", "Sublimação térmica"]', 2, 2, 2),

('Uma pedra rúnica de \"Cálcio arcano\" (Ca) reage com cloro para formar cloreto de cálcio. Sabendo que o cálcio é um metal alcalino-terroso que perde 2 elétrons e o cloro ganha 1 elétron, qual a fórmula molecular correta desse sal rúnico?', 
 '["CaCl", "CaCl₂", "Ca₂Cl", "Ca₂Cl₂"]', 1, 2, 2),

('Uma criatura de ferro da masmorra começa a sofrer oxidação lenta sob a humidade do ar, formando ferrugem vermelha (Fe₂O₃). Nesse processo químico natural de corrosão, qual agente atua sofrendo redução?', 
 '["O oxigênio do ar (O₂)", "O ferro metálico (Fe)", "A água das masmorras (H₂O)", "O dióxido de carbono (CO₂)"]', 0, 2, 2),

('Em um experimento de alquimia, o mago descobre que a adição de pó de ouro catalítico aumenta a velocidade da reação de síntese da poção sem ser consumido no processo. Qual a função de um catalisador em uma reação química?', 
 '["Aumentar a energia de ativação e a temperatura", "Diminuir a velocidade da reação química", "Diminuir a energia de ativação de caminhos alternativos", "Alterar a constante de equilíbrio químico final"]', 2, 2, 2),

('Uma poção alcalina estabilizada possui uma concentração de íons hidróxido (OH-) muito maior que a de íons hidrogênio (H+). Qual o valor aproximado do pH dessa poção na escala padrão a 25°C?', 
 '["pH menor que 7", "pH igual a 7", "pH maior que 7", "pH menor que 0"]', 2, 2, 2),

('O mago estuda o gás metano (CH₄) gerado pela decomposição de slimes orgânicos. A geometria molecular desse composto, em que o átomo de Carbono central liga-se covalentemente a 4 átomos de Hidrogênio, é descrita como:', 
 '["Linear", "Trigonal plana", "Tetraédrica", "Piramidal"]', 2, 2, 2),

('Um pergaminho descreve o \"Carbono arcano\" (C) em sua forma de grafite e em sua forma de diamante indestrutível. Embora compostos pelo mesmo elemento químico puro, possuem estruturas cristalinas diferentes. Esse fenômeno químico é chamado de:', 
 '["Isomeria espacial", "Alotropia", "Isotopia atômica", "Ressonância molecular"]', 1, 2, 2),

('Para resfriar uma poção fervente, o alquimista dissolve nitrato de amônio em água. O frasco fica extremamente gelado ao toque porque a dissolução absorve calor do ambiente. Reações que absorvem calor são classificadas como:', 
 '["Exotérmicas", "Isotérmicas", "Endotérmicas", "Adiabáticas"]', 2, 2, 2),

('Um slime de ácido sulfúrico (H₂SO₄) ataca o guerreiro. Sendo um ácido forte de Arrhenius bi-protonado, quantos hidrogênios ionizáveis ele libera por molécula em solução aquosa?', 
 '["1", "2", "3", "4"]', 1, 2, 2),

('A poção \"Luz de Fósforo\" brilha no escuro devido à combustão do fósforo branco (P₄). A ligação que ocorre entre os não-metais idênticos de fósforo se dá por compartilhamento equitativo de elétrons. Essa ligação é do tipo:', 
 '["Ligação covalente apolar", "Ligação covalente polar", "Ligação iônica forte", "Ligação metálica instável"]', 0, 2, 2),

('O mago da torre quer neutralizar 1 mol de ácido clorídrico (HCl) usando hidróxido de sódio (NaOH) na reação: HCl + NaOH -> NaCl + H₂O. Quantos mols de NaOH são necessários para neutralizar completamente o ácido?', 
 '["0,5 mol", "1 mol", "2 mols", "3 mols"]', 1, 2, 2),

('Uma liga rúnica leve para botas de voo é feita de Alumínio (Al). O átomo neutro de alumínio possui número atômico 13. Quantos elétrons ele possui em sua camada de valência (distribuição eletrônica 2, 8, 3)?', 
 '["1 elétron", "2 elétrons", "3 elétrons", "8 elétrons"]', 2, 2, 2);


-- ==========================================
-- ANDAR 3 - FÍSICA (26 Perguntas)
-- ==========================================

INSERT INTO perguntas (question, options, answer, andar_id, nivel_progresso) VALUES
('O mago lança uma bola de fogo (Fireball) horizontalmente do topo de uma plataforma com velocidade constante de 10 m/s. Se ela atinge o chão após 2 segundos (desconsiderando a resistência do ar), qual a distância horizontal percorrida pela bola de fogo?', 
 '["5 metros", "10 metros", "20 metros", "40 metros"]', 2, 3, 1),

('Para abrir um portal mágico de teletransporte, o mago canaliza energia elétrica através de runas dispostas em circuito paralelo. Se uma runa falha e se apaga (circuito aberto), o que acontece com a corrente elétrica nas outras runas do circuito paralelo?', 
 '["A corrente zera em todas as runas", "As outras runas continuam funcionando de forma independente", "A corrente nas outras runas cai pela metade", "Todas as runas queimam instantaneamente"]', 1, 3, 2),

('Uma runa de gravidade reversa aplica uma força constante para cima de 15 N em um bloco rúnico de massa 1 kg. Sabendo que a aceleração da gravidade local é de 10 m/s² para baixo, qual a aceleração resultante do bloco para cima? (F_res = m * a)', 
 '["5 m/s²", "15 m/s²", "10 m/s²", "25 m/s²"]', 0, 3, 2),

('O robô sentinela emite um feixe de luz mágica que reflete perfeitamente em um espelho de prata arcano. Se o ângulo de incidência do feixe luminoso em relação à normal é de 30°, qual o ângulo de reflexão do feixe segundo as leis da óptica geométrica?', 
 '["60°", "30°", "90°", "0°"]', 1, 3, 1),

('Um mago usa telecinese para empurrar um baú de tesouro com uma força constante de 50 N por uma distância de 4 metros na mesma direção da força. Qual o trabalho físico (W = F * d) realizado pela telecinese do mago sobre o baú?', 
 '["100 Joules", "12,5 Joules", "200 Joules", "50 Joules"]', 2, 3, 1),

('A poção \"Congelamento Rápido\" funciona absorvendo calor rapidamente da água líquida ao redor até que ela solidifique em gelo. O calor que provoca a mudança de estado físico sem alterar a temperatura do sistema é chamado de:', 
 '["Calor sensível", "Calor específico", "Calor de irradiação", "Calor latente"]', 3, 3, 2),

('Uma criatura mecânica flutua na água mágica da fonte da masmorra. Segundo o princípio de Arquimedes, o empuxo vertical para cima que atua sobre a criatura flutuante é igual ao:', 
 '["Volume total do corpo da criatura", "Peso do volume de líquido deslocado pela criatura", "Peso próprio da criatura no vácuo", "Dobro do volume submerso da criatura"]', 1, 3, 2),

('As bobinas de tesla da sala de robôs acumulam cargas elétricas estáticas de sinais opostos. De acordo com a Lei de Coulomb, se a distância entre duas cargas elétricas idênticas for duplicada, o que acontece com a força eletrostática entre elas?', 
 '["Fica quatro vezes menor (dividida por 4)", "Fica duas vezes menor (dividida por 2)", "Fica quatro vezes maior (multiplicada por 4)", "Permanece exatamente igual"]', 0, 3, 2),

('A espada rúnica do guerreiro brilha com calor incandescente. A transferência desse calor térmico através do contato direto da lâmina de metal quente com a carapaça de gelo de um slime ocorre principalmente por qual mecanismo físico?', 
 '["Radiação", "Convecção", "Condução", "Sublimação"]', 2, 3, 1),

('Um sino mágico de cristal é golpeado e emite um som agudo de alta frequência que ressoa pela torre. O som é uma onda mecânica longitudinal. Qual das seguintes afirmações sobre ondas sonoras é correta sob a física clássica?', 
 '["O som pode se propagar livremente no vácuo absoluto", "O som se propaga mais rapidamente em meios sólidos do que gasosos", "A velocidade do som independe da densidade do meio de propagação", "O som é uma onda eletromagnética de alta intensidade"]', 1, 3, 2),

('Uma flecha encantada é disparada com energia cinética inicial de 100 J. À medida que sobe para atingir um gárgula no topo da torre, ela perde velocidade e ganha altura. Desconsiderando atritos, em qual tipo de energia a energia cinética está se convertendo?', 
 '["Energia potencial gravitacional", "Energia potencial elástica", "Energia térmica radiante", "Energia química armazenada"]', 0, 3, 1),

('O mago estuda um prisma de cristal que divide um feixe de luz mágica branca em todas as cores do arco-íris. Esse fenômeno físico de separação de cores devido à variação do índice de refração com a frequência é chamado de:', 
 '["Reflexão total", "Difração rúnica", "Dispersão luminosa", "Polarização linear"]', 2, 3, 2),

('Um robô de patrulha movimenta-se em linha reta de acordo com a função horária da posição S(t) = 5 + 3t (no Sistema Internacional). Qual a velocidade linear de patrulha desse robô?', 
 '["5 m/s", "3 m/s", "8 m/s", "15 m/s"]', 1, 3, 1),

('Uma criatura robô do andar de Física colide elasticamente com outra criatura de mesma massa que estava parada. Segundo as leis de conservação física, o que ocorre com a quantidade de movimento total do sistema isolado após a colisão?', 
 '["Permanece constante (conserva-se)", "Reduz-se a zero instantaneamente", "Duplica de valor devido ao impacto", "Fica reduzida pela metade"]', 0, 3, 2),

('O mago usa um espelho côncavo mágico para projetar uma imagem real e invertida de uma runa brilhante na parede oposta da masmorra. Qual o tipo de lente ou espelho que pode gerar uma imagem real de um objeto real?', 
 '["Espelho côncavo (ou lente convergente)", "Espelho convexo (ou lente divergente)", "Espelho plano liso ordinário", "Lente divergente pura apenas"]', 0, 3, 2),

('Um robô sentinela carrega uma bateria de 12 Volts que alimenta seus circuitos com uma resistência elétrica de 4 Ohms. De acordo com a Primeira Lei de Ohm (U = R * I), qual a intensidade da corrente elétrica que flui pelo robô?', 
 '["3 Ampères", "48 Ampères", "0,33 Ampères", "8 Ampères"]', 0, 3, 2),

('Um mago aplica uma força constante de 20 N sobre um bloco de pedra rúnica de 2 kg que estava em repouso. Desconsiderando o atrito do solo, qual a aceleração sofrida pelo bloco de acordo com a Segunda Lei de Newton? (a = F / m)', 
 '["5 m/s²", "10 m/s²", "20 m/s²", "40 m/s²"]', 1, 3, 2),

('A bola de fogo lançada pelo mago viaja em linha reta com velocidade que aumenta uniformemente de 2 m/s para 14 m/s em um intervalo de tempo de 3 segundos. Qual a aceleração média dessa bola de fogo em Movimento Uniformemente Variado (MUV)?', 
 '["2 m/s²", "4 m/s²", "6 m/s²", "12 m/s²"]', 1, 3, 2),

('Um portal de gravidade do andar 3 puxa o guerreiro com uma força gravitacional de atração. Se a massa da Terra mágica é M e a do guerreiro é m, de acordo com a Lei da Gravitação Universal de Newton, a força gravitacional é:', 
 '["Inversamente proporcional ao quadrado da distância entre eles", "Diretamente proporcional à distância entre eles", "Independente do produto das massas", "Inversamente proporcional à distância simples"]', 0, 3, 2),

('O mago usa um guindaste hidráulico rúnico para elevar um golem pesado de pedra. O princípio físico por trás do elevador hidráulico, onde a pressão aplicada a um fluido incompressível é transmitida igualmente em todas as direções, é o:', 
 '["Princípio de Arquimedes", "Princípio de Pascal", "Princípio de Bernoulli", "Efeito Joule-Thomson"]', 1, 3, 2),

('A armadura eletrostática do mago repele flechas de energia metálica polarizadas. A lei física que define que cargas elétricas de mesmo sinal se repelem e de sinais opostos se atraem é a:', 
 '["Lei de Ampère", "Lei de Faraday-Lenz", "Lei de Coulomb (ou forças eletrostáticas)", "Lei de Gauss do magnetismo"]', 2, 3, 2),

('Um robô mecânico arrasta um baú pesado de 10 kg sobre o piso de pedra rugosa da masmorra. Se o coeficiente de atrito cinético entre o baú e o piso é 0,3 (adotando g = 10 m/s²), qual a força de atrito cinético oposta ao movimento? (F_at = mi * N)', 
 '["3 N", "30 N", "100 N", "0,3 N"]', 1, 3, 2),

('O calor emitido por uma runa de fogo irradia energia térmica através do espaço vazio da câmara de testes, aquecendo o ar. A transferência de calor que ocorre por meio de ondas eletromagnéticas (infravermelho) sem contato material é a:', 
 '["Condução", "Convecção", "Irradiação (ou Radiação térmica)", "Sublimação"]', 2, 3, 2),

('Um guerreiro gira um mangual rúnico em um movimento circular uniforme acima de sua cabeça. A aceleração direcionada para o centro da trajetória circular que mantém o mangual em órbita é a:', 
 '["Aceleração tangencial", "Aceleração centrípeta", "Aceleração gravitacional", "Aceleração angular"]', 1, 3, 2),

('Um feixe de luz de cura passa do ar para o cristal mágico da fonte. Ao mudar de meio, a luz sofre alteração em sua velocidade e direção de propagação. Esse fenômeno físico da luz é conhecido como:', 
 '["Reflexão", "Refração", "Difração", "Dispersão"]', 1, 3, 2),

('Uma runa de eletrocussão gera uma corrente elétrica que passa pela armadura do inimigo, aquecendo-a devido à resistência elétrica do metal. Esse efeito de transformação de energia elétrica em energia térmica é chamado de:', 
 '["Efeito Doppler", "Efeito Joule", "Efeito Fotoelétrico", "Efeito Hall"]', 1, 3, 2);
