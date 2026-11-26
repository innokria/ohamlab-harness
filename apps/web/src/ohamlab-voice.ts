// OhamLab built-in voice: no cloud fallback.
export function installVoiceControls(): void {
  if (document.getElementById('ohamlab-voice')) return
  const button = document.createElement('button')
  button.id = 'ohamlab-voice'; button.type = 'button'; button.textContent = '🎙'; button.title = 'OhamLab local voice input'
  button.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:1000;padding:10px;border-radius:12px;background:#fff;color:#222;border:1px solid #aaa'
  button.onclick = async () => {
    const Recognition = (window as any).SpeechRecognition ?? (window as any).webkitSpeechRecognition
    if (!Recognition || !('processLocally' in Recognition.prototype)) { alert('On-device speech recognition is unavailable in this browser. No cloud fallback is used.'); return }
    const recognition = new Recognition(); recognition.processLocally = true; recognition.lang = navigator.language
    recognition.onresult = (event: any) => {
      const fields = Array.from(document.querySelectorAll<HTMLTextAreaElement>('textarea')).filter(el => el.getClientRects().length > 0)
      const field = fields[fields.length - 1]; if (!field) return
      Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')?.set?.call(field, event.results[0][0].transcript)
      field.dispatchEvent(new Event('input', { bubbles: true })); field.focus()
    }
    recognition.onerror = () => { button.textContent = '🎙'; alert('Local speech recognition failed or language pack unavailable.') }
    recognition.onend = () => { button.textContent = '🎙' }; button.textContent = 'Listening…'
    try { recognition.start() } catch { button.textContent = '🎙' }
  }
  const speak = document.createElement('button'); speak.type = 'button'; speak.textContent = '🔊'; speak.title = 'Read selected text using local voice'; speak.style.cssText = button.style.cssText + ';right:70px'
  speak.onmousedown = event => event.preventDefault()
  speak.onclick = () => {
    const text = window.getSelection()?.toString(); if (!text) { alert('Select text to read aloud.'); return }
    const voice = window.speechSynthesis?.getVoices().find(v => v.localService && v.lang.startsWith(navigator.language.split('-')[0] ?? 'en'))
    if (!voice) { alert('No local speech synthesis voice available.'); return }
    const utterance = new SpeechSynthesisUtterance(text); utterance.voice = voice; window.speechSynthesis.speak(utterance)
  }
  document.body.append(button, speak)
}
