shader_type canvas_item;

// transicao de tela:
// 0 = circulo fechando / abrindo
// 1 = fade escuro

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform float suavidade : hint_range(0.001, 0.5) = 0.07;
uniform vec4 cor_fundo : source_color = vec4(0.02, 0.03, 0.06, 1.0);
uniform vec4 cor_borda : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float largura_borda : hint_range(0.0, 0.2) = 0.04;
uniform int modo : hint_range(0, 1) = 0; // 0 = circulo, 1 = fade

void fragment() {
	vec2 centro = vec2(0.5, 0.5);
	// arruma o aspect ratio pro circulo nao ficar oval
	float aspect = SCREEN_PIXEL_SIZE.y / max(SCREEN_PIXEL_SIZE.x, 0.00001);
	vec2 uv = SCREEN_UV - centro;
	uv.x *= aspect;
	float dist = length(uv);
	
	if (modo == 0) {
		// transicao em circulo
		float max_raio = 1.15;
		float raio = (1.0 - progresso) * max_raio;
		
		float alpha = smoothstep(raio - suavidade, raio + suavidade, dist);
		
		// brilho na borda do circulo
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
		// fade simples com vinheta escura nas bordas
		float vinheta = smoothstep(0.2, 0.85, dist);
		float alpha = clamp(progresso * 1.15 + vinheta * 0.35 * progresso, 0.0, 1.0);
		vec4 col = cor_fundo;
		col.a = alpha;
		COLOR = col;
	}
}
