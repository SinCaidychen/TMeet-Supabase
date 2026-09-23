const prisma = require("../config/prisma");

async function me(req, res) {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) return res.status(404).json({ error: "User not found" });
  const { passwordHash, ...rest } = user;
  res.json(rest);
}

// Called by the mobile app whenever the device gets a new GPS fix.
async function updateLocation(req, res) {
  const { lat, lng } = req.body;
  if (typeof lat !== "number" || typeof lng !== "number") {
    return res.status(400).json({ error: "lat and lng must be numbers" });
  }
  await prisma.user.update({ where: { id: req.userId }, data: { lat, lng } });
  res.json({ ok: true });
}

// Called once by the onboarding flow after the OpenAI personality-summary step (frontend team
// owns the actual OpenAI call; this just persists the result).
async function updateOnboarding(req, res) {
  const { motto, tags, personality } = req.body;
  const user = await prisma.user.update({
    where: { id: req.userId },
    data: { motto, tags, personality },
  });
  const { passwordHash, ...rest } = user;
  res.json(rest);
}

module.exports = { me, updateLocation, updateOnboarding };
