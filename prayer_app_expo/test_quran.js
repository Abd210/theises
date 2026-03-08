import fetch from 'node-fetch';
async function test() {
  const res = await fetch('https://api.alquran.cloud/v1/page/21/quran-uthmani');
  const json = await res.json();
  const ayahs = json.data.ayahs;
  console.log("Ayah count:", ayahs.length);
  console.log("First ayah numberInSurah:", ayahs[0].numberInSurah);
  console.log("First ayah text snippet:", ayahs[0].text.substring(0, 30));
}
test();
