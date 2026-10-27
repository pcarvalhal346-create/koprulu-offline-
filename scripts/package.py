#!/usr/bin/env python3
"""Package the PWA and a self-contained, playable desktop HTML; no dependencies."""
import argparse
import base64
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]


def portable_html():
    engine = (ROOT / 'engine.mjs').read_text(encoding='utf-8')
    exports = re.findall(r'^export (?:const|function|class) (\w+)', engine, re.M)
    namespace = re.sub(r'^export ', '', engine, flags=re.M)
    namespace = 'const Engine=(()=>{\n' + namespace + '\nreturn {' + ','.join(exports) + '};\n})();\n'
    app = (ROOT / 'app.js').read_text(encoding='utf-8')
    app, count = re.subn(r"^import \{([^}]+)\} from './engine\.mjs';", r'const {\1}=Engine;', app)
    if count != 1:
        raise ValueError('Expected one engine import; update the portable bundler.')
    # An embedded file needs no service worker: its assets are already inline.
    app, count = re.subn(r"^  if\('serviceWorker' in navigator\).*\n", '', app, flags=re.M)
    if count != 1 or re.search(r'^import\s', app, re.M):
        raise ValueError('Unexpected imports or service-worker registration; update the bundler.')
    script = (namespace + app).replace('</script', '<\\/script')
    html = (ROOT / 'index.html').read_text(encoding='utf-8')
    html = html.replace('<head>', '<!--\n' + (ROOT / 'LICENSE').read_text(encoding='utf-8') + '\n-->\n<head>', 1)
    html = html.replace('  <link rel="manifest" href="./manifest.webmanifest">\n', '')
    html = html.replace('<link rel="stylesheet" href="./styles.css">', '<style>\n' + (ROOT / 'styles.css').read_text(encoding='utf-8') + '\n</style>')
    icon = 'data:image/png;base64,' + base64.b64encode((ROOT / 'icons/icon-192.png').read_bytes()).decode('ascii')
    html = html.replace('./icons/icon-192.png', icon)
    html = html.replace('<script type="module" src="./app.js"></script>', '<script type="module">\n' + script + '\n</script>')
    return html


def package(output):
    output.mkdir(parents=True, exist_ok=True)
    portable = portable_html()
    (output / 'koprulu-offline.html').write_text(portable, encoding='utf-8')
    files = ['index.html', 'app.js', 'engine.mjs', 'styles.css', 'sw.js', 'manifest.webmanifest', 'LICENSE', 'README.md']
    files += [str(p.relative_to(ROOT)) for p in sorted((ROOT / 'icons').glob('*')) if p.is_file()]
    with ZipFile(output / 'koprulu-offline.zip', 'w', ZIP_DEFLATED) as archive:
        for name in files:
            archive.write(ROOT / name, 'koprulu-offline/' + name)
        archive.writestr('koprulu-offline/.nojekyll', '')
        archive.writestr('koprulu-offline/JOGAR.html', portable)
        archive.writestr('koprulu-offline/COMECAR.txt',
            'KOPRULU OFFLINE\n\n'
            'COMPUTADOR: abre JOGAR.html num navegador moderno. Nao precisa de servidor nem de internet.\n'
            'Escolhe uma raca e um lider e inicia a campanha.\n'
            'Segue os quatro objetivos na Visao geral. Para experimentar sem esperar, usa Opcoes > Simular +1 hora.\n'
            'Exporta o progresso em Opcoes para guardar uma copia.\n\n'
            'PWA/IPHONE: publica os ficheiros desta pasta num alojamento HTTPS, conforme README.md.\n'
            'Abre o endereco no Safari e usa Partilhar > Adicionar ao ecra principal.\n'
            'JOGAR.html e uma edicao portatil para computador; a PWA usa index.html.\n'
            'Os saves sao locais ao navegador e a origem. Usa exportar/importar para os transferir.\n')
    print(output / 'koprulu-offline.html')
    print(output / 'koprulu-offline.zip')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    package(parser.parse_args().output.resolve())
