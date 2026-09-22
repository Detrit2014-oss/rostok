import { NextRequest, NextResponse } from "next/server";

// Прокси к любому OpenAI-совместимому API (chat/completions).
// Ключ передаётся клиентом в теле запроса и НЕ сохраняется на сервере —
// это тот самый «прокси-бэкенд», который README рекомендует для релиза.
// Нужен, чтобы браузерный демо мог обращаться к провайдерам, блокирующим CORS.

export async function POST(req: NextRequest) {
  let body: {
    baseUrl?: string;
    apiKey?: string;
    model?: string;
    messages?: { role: string; content: string }[];
    temperature?: number;
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ ok: false, error: "invalid json" }, { status: 400 });
  }

  const baseUrl = (body.baseUrl ?? "").trim().replace(/\/+$/, "");
  const apiKey = (body.apiKey ?? "").trim();
  const model = (body.model ?? "").trim();
  const messages = Array.isArray(body.messages) ? body.messages : [];

  if (!baseUrl || !apiKey || !model || messages.length === 0) {
    return NextResponse.json({ ok: false, error: "missing fields" }, { status: 400 });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);

  try {
    const res = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: body.temperature ?? 0.7,
      }),
      signal: controller.signal,
    });

    if (!res.ok) {
      return NextResponse.json({ ok: false, error: `HTTP ${res.status}` });
    }
    const data = await res.json().catch(() => null);
    const content: string | null =
      data?.choices?.[0]?.message?.content ?? null;
    return NextResponse.json({ ok: true, content });
  } catch {
    return NextResponse.json({ ok: false, error: "network" });
  } finally {
    clearTimeout(timeout);
  }
}
