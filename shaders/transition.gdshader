shader_type canvas_item;

// Transição de Cena Arcana - Synthesis
// Suporta dois modos visuais:
// 0 = Portal Iris Circular Mágico (com anel de brilho arcano ciano)
// 1 = Fade Cinematográfico com Vinheta Suave

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform float suavidade : hint_range(0.001, 0.5) = 0.07;
uniform vec4 cor_fundo : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform vec4 cor_borda : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float largura_borda : hint_range(0.0, 0.2) = 0.04;
uniform int modo : hint_range(0, 1) = 0; // 0: Iris, 1: Fade com Vinheta

void fragment() {
	vec2 centro = vec2(0.5, 0.5);
	// Corrige a proporção de tela para o círculo ser perfeitamente redondo em qualquer resolução
	float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.00001);
	vec2 uv = SCREEN_UV - centro;
	uv.x *= aspect;
	float dist = length(uv);
	
	if (modo == 0) {
		// --- MODO PORTAL IRIS CIRCULAR ---
		// Raio máximo que cobre os cantos da tela em 16:9 / ultrawide
		float max_raio = 1.15;
		float raio = (1.0 - progresso) * max_raio;
		
		// Máscara de transparência do orbe central
		float alpha = smoothstep(raio - suavidade, raio + suavidade, dist);
		
		// Halo de energia arcana luminoso na borda do portal
		float halo = 0.0;
		if (progresso > 0.005 && progresso < 0.995) {
			float diff = abs(dist - raio);
			halo = exp(-pow(diff / max(largura_borda, 0.001), 2.0));
		}
		
		vec4 col = cor_fundo;
		col.rgb = mix(col.rgb, cor_borda.rgb, halo * 0.95);
		col.a = clamp(alpha + halo * 0.85, 0.0, 1.0);
		COLOR = col;
	} else {
		// --- MODO FADE SUAVE COM VINHETA CINEMATOGRÁFICA ---
		float vinheta = smoothstep(0.2, 0.85, dist);
		float alpha = clamp(progresso * 1.15 + vinheta * 0.35 * progresso, 0.0, 1.0);
		vec4 col = cor_fundo;
		col.a = alpha;
		COLOR = col;
	}
}
