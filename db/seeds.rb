# Create Platform A (Muench Crowd) with its steps
platform_a = Platform.find_or_create_by!(slug: 'platform-a') do |p|
  p.name = 'Platform A'
  p.active = true
end

# Clear existing steps for Platform A
platform_a.steps.destroy_all

# Create steps for Platform A
platform_a_steps = [
  {
    title: "Investment amount",
    component_type: :amount_input,
    config: { min: 100, max: 5000 },
    order: 1
  },
  {
    title: "Accept terms",
    component_type: :checkbox,
    config: { label: "I accept the terms and conditions." },
    order: 2
  },
  {
    title: "Confirm",
    component_type: :disclaimer,
    config: { text: "Please confirm your investment details." },
    order: 3
  }
]

platform_a_steps.each do |step_data|
  platform_a.steps.create!(step_data)
end

# Create Platform B with its steps
platform_b = Platform.find_or_create_by!(slug: 'platform-b') do |p|
  p.name = 'Platform B'
  p.active = true
end

# Clear existing steps for Platform B
platform_b.steps.destroy_all

# Create steps for Platform B
platform_b_steps = [
  {
    title: "Investment amount",
    component_type: :amount_input,
    config: { min: 500, max: 10000 },
    order: 1
  },
  {
    title: "Enter referral code",
    component_type: :text_input,
    config: { label: "Referral Code", placeholder: "Enter your referral code (optional)" },
    order: 2
  },
  {
    title: "Agree to risk disclaimer",
    component_type: :disclaimer,
    config: { text: "This is a speculative investment. Capital is at risk. Past performance does not guarantee future results." },
    order: 3
  },
  {
    title: "Confirm",
    component_type: :checkbox,
    config: { label: "I confirm that I understand the risks and want to proceed with this investment." },
    order: 4
  }
]

platform_b_steps.each do |step_data|
  platform_b.steps.create!(step_data)
end

puts "Created Platform A: #{platform_a.name} with #{platform_a.steps.count} steps"
puts "Created Platform B: #{platform_b.name} with #{platform_b.steps.count} steps"
