RUBRIC = {
    "id": [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16
    ],
    "criterion": [
        "Modal Verb Strength",
        "Hedging Frequency & Type",
        "Qualifier Density",
        "Acknowledgement of Limitations",
        "Caution-Signaling Connectors",
        "Assertiveness & Voice",
        "Active/Passive Voice Ratio",
        "Sentence Length & Directness",
        "Imperative-Form Occurrence",
        "Pronoun Commitment",
        "Novelty-Claim Strength",
        "Jargon/Technicality Density",
        "Emotional Valence",
        "Evidence & Citation Usage",
        "Practical/Impact Orientation",
        "Readability"
    ],
    "description": [
        "Balance of weak ('may', 'might') vs. strong ('will', 'cannot') modals",
        "Frequency of single-word qualifiers and larger stance phrases ('it seems that', 'we believe')",
        "Use of modifiers ('to some extent', 'relatively') that soften claims",
        "Explicit mention of caveats or boundary conditions ('within context', 'may not generalize')",
        "Use of 'however', 'nevertheless', 'on the other hand' to signal complexity",
        "Proportion of unequivocal verbs ('prove', 'confirm') vs. tentative verbs ('suggest', 'explore')",
        "Ratio of active ('we test') to passive ('it was tested') constructions",
        "Degree of multi-clausal, convoluted sentences vs. brief, single-clause statements",
        "Presence of direct commands ('Apply X') vs. none or only embedded suggestions",
        "Use of first-person ('we', 'I') vs. impersonal constructions ('the authors')",
        "Boldness of originality claims ('first to', 'novel framework')",
        "Density of undefined field-specific terms vs. accessible language",
        "Presence of emotionally charged adjectives ('revolutionary', 'urgent') vs. neutral descriptors",
        "How consistently claims are backed by data, statistics or literature citations",
        "Emphasis on real-world applications, policy or practice implications",
        "Precision and ease with which a reader can understand the author's intended meaning"
    ],
    "scale": [
        "1=only weak; 10=only strong",
        "1=continuous hedging; 10=no hedges",
        "1=extensive qualifiers; 10=none",
        "1=numerous limitations; 10=none or implicit only",
        "1=frequent; 5=occasional; 10=none",
        "1=almost all tentative; 10=almost all assertive",
        "1=90% passive; 5=50/50; 10=90% active",
        "1=way long; 10=way short",
        "1=no imperatives; 10=dominant",
        "1=fully impersonal; 10=fully first-person",
        "1=no novelty claim; 5=hedged; 10=grandlose",
        "1=minimal jargon; 10=dense undefined jargon",
        "1=none; 10=frequent",
        "1=none; 10=every claim backed",
        "1=none; 5=may inform practice; 10=will transform practice",
        "1=difficult to understand; 10=incredibly easy to understand"
    ]
}

def dict_of_lists_to_list_of_dicts(rubric_dict):
    return [
        dict(zip(rubric_dict.keys(), values))
        for values in zip(*rubric_dict.values())
    ]

def build_checklist(rubric_list):
    lines = [
        f"{r['id']}. {r['criterion']}: {r['description']}. Scale: {r['scale']}"
        for r in rubric_list
    ]
    return "\n".join(lines)

LIST_RUBRIC = dict_of_lists_to_list_of_dicts(RUBRIC)
CHECKLIST_RUBRIC = build_checklist(LIST_RUBRIC)
